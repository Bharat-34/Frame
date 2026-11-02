import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../domain/media_repository.dart';
import '../domain/models.dart';

const _permission = PermissionRequestOption(
  androidPermission: AndroidPermission(
    type: RequestType.common,
    mediaLocation: false,
  ),
);

/// PhotoManager-backed library. Asset entities stay in this file so the
/// rest of the app only sees [MediaAsset].
class PhotoManagerMediaRepository implements MediaRepository, MediaImages {
  final Map<String, AssetPathEntity> _paths = {};
  final Map<String, AssetEntity> _entities = {};

  @override
  void invalidatePaths() => _paths.clear();

  void dispose() {
    _paths.clear();
    _entities.clear();
  }

  @override
  Future<LibraryAccess> currentAccess() {
    return _guard(() async {
      final state = await PhotoManager.getPermissionState(
        requestOption: _permission,
      );
      return _mapAccess(state);
    });
  }

  @override
  Future<LibraryAccess> requestAccess() {
    return _guard(() async {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: _permission,
      );
      return _mapAccess(state);
    });
  }

  @override
  Future<void> openSystemSettings() {
    return PhotoManager.openSetting();
  }

  @override
  Future<void> manageLimitedAccess() {
    return PhotoManager.presentLimited(type: RequestType.common);
  }

  @override
  Future<List<MediaAlbum>> albums() {
    return _guard(() async {
      final paths = await PhotoManager.getAssetPathList(
        hasAll: false,
        onlyAll: false,
        type: RequestType.common,
        filterOption: _standardFilter(newestFirst: true),
      );
      final albums = <MediaAlbum>[];
      for (final path in paths) {
        if (path.isAll) continue;
        final count = await path.assetCountAsync;
        if (count == 0) continue;
        final cover = await path.getAssetListRange(start: 0, end: 1);
        String? coverId;
        if (cover.isNotEmpty) {
          _remember(cover.first);
          coverId = cover.first.id;
        }
        albums.add(
          MediaAlbum(
            id: path.id,
            name: path.name.isEmpty ? 'Album' : path.name,
            count: count,
            coverAssetId: coverId,
          ),
        );
      }
      albums.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return albums;
    });
  }

  @override
  Future<MediaPage> page({
    required LibraryQuery query,
    required int page,
    required int size,
  }) {
    return _guard(() async {
      final path = await _resolvePath(query);
      if (path == null) return MediaPage.empty;
      final total = await path.assetCountAsync;
      if (total == 0 || page * size >= total) {
        return MediaPage(items: const [], total: total, hasMore: false);
      }
      final entities = await path.getAssetListPaged(page: page, size: size);
      final items = <MediaAsset>[];
      for (final entity in entities) {
        if (entity.type != AssetType.image && entity.type != AssetType.video) {
          continue;
        }
        _remember(entity);
        items.add(_toAsset(entity));
      }
      final fetchedThrough = page * size + entities.length;
      return MediaPage(
        items: items,
        total: total,
        hasMore: fetchedThrough < total,
      );
    });
  }

  @override
  Future<void> setFavorite(String id, bool favorite) {
    return _guard(() async {
      final entity = await _entity(id);
      if (entity == null) {
        throw const GalleryFailure('That item is no longer on this device.');
      }
      final AssetEntity updated;
      if (Platform.isAndroid) {
        updated = await PhotoManager.editor.android.favoriteAsset(
          entity: entity,
          favorite: favorite,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        updated = await PhotoManager.editor.darwin.favoriteAsset(
          entity: entity,
          favorite: favorite,
        );
      } else {
        throw const GalleryFailure(
          'Favorites are not available on this device.',
        );
      }
      _entities[id] = updated;
      _paths.clear();
    });
  }

  @override
  Future<List<String>> delete(List<String> ids) {
    return _guard(() async {
      if (ids.isEmpty) return const [];
      final deleted = await PhotoManager.editor.deleteWithIds(ids);
      for (final id in deleted) {
        _entities.remove(id);
      }
      _paths.clear();
      return deleted;
    });
  }

  @override
  Future<String?> filePath(String id) async {
    final entity = await _entity(id);
    if (entity == null) return null;
    final file = await entity.file;
    return file?.path;
  }

  @override
  Future<MediaDetails> details(String id) async {
    final entity = await _entity(id);
    if (entity == null) {
      throw const GalleryFailure('That item is no longer on this device.');
    }
    final file = await entity.file;
    final title = entity.title ?? await entity.titleAsync;
    return MediaDetails(
      title: title.isEmpty ? 'Untitled' : title,
      mimeType: entity.mimeType,
      byteSize: await file?.length(),
    );
  }

  @override
  ImageProvider thumbnail(String id, {required int side}) {
    final entity = _entities[id];
    if (entity == null) return MemoryImage(_pixel);
    return AssetEntityImageProvider(
      entity,
      isOriginal: false,
      thumbnailSize: ThumbnailSize.square(_bucket(side)),
      thumbnailFormat: ThumbnailFormat.jpeg,
    );
  }

  @override
  ImageProvider display(String id) {
    final entity = _entities[id];
    if (entity == null) return MemoryImage(_pixel);
    return AssetEntityImageProvider(
      entity,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize.square(1600),
      thumbnailFormat: ThumbnailFormat.jpeg,
    );
  }

  Future<AssetPathEntity?> _resolvePath(LibraryQuery query) async {
    final cached = _paths[query.cacheKey];
    if (cached != null) return cached;
    final paths = await PhotoManager.getAssetPathList(
      hasAll: true,
      onlyAll: query.albumId == null,
      type: _requestType(query.kind),
      filterOption: _filter(query),
    );
    AssetPathEntity? path;
    if (query.albumId == null) {
      for (final candidate in paths) {
        if (candidate.isAll) {
          path = candidate;
          break;
        }
      }
      path ??= paths.isEmpty ? null : paths.first;
    } else {
      for (final candidate in paths) {
        if (candidate.id == query.albumId) {
          path = candidate;
          break;
        }
      }
    }
    if (path != null) _paths[query.cacheKey] = path;
    return path;
  }

  PMFilter _filter(LibraryQuery query) {
    if (!query.favoritesOnly) {
      return _standardFilter(
        newestFirst: query.newestFirst,
        createdFrom: query.createdFrom,
        createdTo: query.createdTo,
      );
    }
    final filter = AdvancedCustomFilter()
      ..addWhereCondition(
        ColumnWhereCondition(
          column: CustomColumns.base.isFavorite,
          operator: '==',
          value: '1',
        ),
      )
      ..addOrderBy(
        column: CustomColumns.base.createDate,
        isAsc: !query.newestFirst,
      );
    final from = query.createdFrom;
    final to = query.createdTo;
    if (from != null) {
      filter.addWhereCondition(
        DateColumnWhereCondition(
          column: CustomColumns.base.createDate,
          operator: '>=',
          value: from,
        ),
      );
    }
    if (to != null) {
      filter.addWhereCondition(
        DateColumnWhereCondition(
          column: CustomColumns.base.createDate,
          operator: '<=',
          value: to.subtract(const Duration(milliseconds: 1)),
        ),
      );
    }
    return filter;
  }

  FilterOptionGroup _standardFilter({
    required bool newestFirst,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) {
    final hasWindow = createdFrom != null || createdTo != null;
    return FilterOptionGroup(
      imageOption: const FilterOption(
        needTitle: true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      videoOption: const FilterOption(
        needTitle: true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      createTimeCond: DateTimeCond(
        min: createdFrom ?? DateTime.fromMillisecondsSinceEpoch(0),
        max: createdTo == null
            ? DateTime.now()
            : createdTo.subtract(const Duration(milliseconds: 1)),
        ignore: !hasWindow,
      ),
      orders: [
        OrderOption(type: OrderOptionType.createDate, asc: !newestFirst),
      ],
    );
  }

  RequestType _requestType(MediaKind? kind) {
    return switch (kind) {
      MediaKind.image => RequestType.image,
      MediaKind.video => RequestType.video,
      null => RequestType.common,
    };
  }

  Future<AssetEntity?> _entity(String id) async {
    final cached = _entities[id];
    if (cached != null) return cached;
    final loaded = await AssetEntity.fromId(id);
    if (loaded != null) _remember(loaded);
    return loaded;
  }

  void _remember(AssetEntity entity) => _entities[entity.id] = entity;

  MediaAsset _toAsset(AssetEntity entity) {
    return MediaAsset(
      id: entity.id,
      kind: entity.type == AssetType.video ? MediaKind.video : MediaKind.image,
      width: entity.orientatedWidth,
      height: entity.orientatedHeight,
      duration: Duration(seconds: entity.duration),
      createdAt: entity.createDateTime,
      isFavorite: entity.isFavorite,
      title: entity.title,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  LibraryAccess _mapAccess(PermissionState state) {
    return switch (state) {
      PermissionState.authorized => LibraryAccess.granted,
      PermissionState.limited => LibraryAccess.limited,
      PermissionState.restricted => LibraryAccess.restricted,
      PermissionState.denied => LibraryAccess.denied,
      PermissionState.notDetermined => LibraryAccess.unknown,
    };
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GalleryFailure {
      rethrow;
    } on StateError {
      throw const GalleryFailure('That change was not saved.');
    } catch (_) {
      throw const GalleryFailure(
        'Something went wrong while reading the library.',
      );
    }
  }
}

int _bucket(int side) {
  if (side <= 280) return 240;
  if (side <= 520) return 480;
  return 800;
}

/// 1×1 transparent pixel used when an id is not in the cache yet.
final Uint8List _pixel = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, //
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, //
  120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, //
  68, 174, 66, 96, 130,
]);
