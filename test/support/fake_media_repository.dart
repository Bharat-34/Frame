import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:frame/features/gallery/domain/media_repository.dart';
import 'package:frame/features/gallery/domain/models.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository(this.assets);

  final List<MediaAsset> assets;

  @override
  Future<LibraryAccess> currentAccess() async => LibraryAccess.granted;

  @override
  Future<LibraryAccess> requestAccess() async => LibraryAccess.granted;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> manageLimitedAccess() async {}

  @override
  Future<List<MediaAlbum>> albums() async => const [];

  @override
  Future<MediaPage> page({
    required LibraryQuery query,
    required int page,
    required int size,
  }) async {
    final filtered = assets.where((asset) {
      if (query.favoritesOnly && !asset.isFavorite) return false;
      if (query.kind != null && asset.kind != query.kind) return false;
      final from = query.createdFrom;
      final to = query.createdTo;
      if (from != null && asset.createdAt.isBefore(from)) return false;
      if (to != null && !asset.createdAt.isBefore(to)) return false;
      return true;
    }).toList();
    filtered.sort((a, b) {
      final order = a.createdAt.compareTo(b.createdAt);
      return query.newestFirst ? -order : order;
    });
    final start = page * size;
    if (start >= filtered.length) {
      return MediaPage(items: const [], total: filtered.length, hasMore: false);
    }
    final items = filtered.skip(start).take(size).toList();
    return MediaPage(
      items: items,
      total: filtered.length,
      hasMore: start + items.length < filtered.length,
    );
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {}

  @override
  Future<List<String>> delete(List<String> ids) async => ids;

  @override
  Future<String?> filePath(String id) async => null;

  @override
  Future<MediaDetails> details(String id) async {
    return const MediaDetails(title: 'Photo');
  }

  @override
  void invalidatePaths() {}
}

class FakeMediaImages implements MediaImages {
  @override
  ImageProvider thumbnail(String id, {required int side}) =>
      MemoryImage(_pixel);

  @override
  ImageProvider display(String id) => MemoryImage(_pixel);
}

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);
