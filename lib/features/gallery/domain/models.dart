/// Why a library read or change could not finish.
class GalleryFailure implements Exception {
  const GalleryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// How much of the on-device library Frame is allowed to see.
enum LibraryAccess { unknown, granted, limited, denied, restricted }

extension LibraryAccessAccess on LibraryAccess {
  bool get hasAccess =>
      this == LibraryAccess.granted || this == LibraryAccess.limited;

  bool get isLimited => this == LibraryAccess.limited;
}

enum MediaKind { image, video }

/// A photo or video already stored on the device.
class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.kind,
    required this.width,
    required this.height,
    required this.duration,
    required this.createdAt,
    required this.isFavorite,
    this.title,
    this.latitude,
    this.longitude,
  });

  final String id;
  final MediaKind kind;
  final int width;
  final int height;
  final Duration duration;
  final DateTime createdAt;
  final bool isFavorite;
  final String? title;
  final double? latitude;
  final double? longitude;

  bool get isVideo => kind == MediaKind.video;

  MediaAsset copyWith({bool? isFavorite, String? title}) {
    return MediaAsset(
      id: id,
      kind: kind,
      width: width,
      height: height,
      duration: duration,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      title: title ?? this.title,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// A device album, such as Camera or Screenshots.
class MediaAlbum {
  const MediaAlbum({
    required this.id,
    required this.name,
    required this.count,
    this.coverAssetId,
  });

  final String id;
  final String name;
  final int count;
  final String? coverAssetId;
}

/// One page of a paged library query.
class MediaPage {
  const MediaPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<MediaAsset> items;
  final int total;
  final bool hasMore;

  static const empty = MediaPage(items: [], total: 0, hasMore: false);
}

/// File facts loaded only when the details sheet opens.
class MediaDetails {
  const MediaDetails({required this.title, this.mimeType, this.byteSize});

  final String title;
  final String? mimeType;
  final int? byteSize;
}

/// What a screen wants from the library.
///
/// Screens share one controller family keyed by this value, so Photos,
/// an album, and Saved can each page independently.
class LibraryQuery {
  const LibraryQuery({
    this.albumId,
    this.kind,
    this.favoritesOnly = false,
    this.newestFirst = true,
    this.createdFrom,
    this.createdTo,
  });

  final String? albumId;
  final MediaKind? kind;
  final bool favoritesOnly;
  final bool newestFirst;

  /// Inclusive.
  final DateTime? createdFrom;

  /// Exclusive.
  final DateTime? createdTo;

  String get cacheKey => [
    albumId ?? '*',
    kind?.name ?? '*',
    favoritesOnly,
    newestFirst,
    createdFrom?.millisecondsSinceEpoch,
    createdTo?.millisecondsSinceEpoch,
  ].join('|');

  LibraryQuery copyWith({
    String? albumId,
    MediaKind? kind,
    bool? favoritesOnly,
    bool? newestFirst,
    DateTime? createdFrom,
    DateTime? createdTo,
    bool clearKind = false,
    bool clearCreated = false,
    bool clearAlbum = false,
  }) {
    return LibraryQuery(
      albumId: clearAlbum ? null : (albumId ?? this.albumId),
      kind: clearKind ? null : (kind ?? this.kind),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      newestFirst: newestFirst ?? this.newestFirst,
      createdFrom: clearCreated ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearCreated ? null : (createdTo ?? this.createdTo),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryQuery &&
        other.albumId == albumId &&
        other.kind == kind &&
        other.favoritesOnly == favoritesOnly &&
        other.newestFirst == newestFirst &&
        other.createdFrom == createdFrom &&
        other.createdTo == createdTo;
  }

  @override
  int get hashCode => Object.hash(
    albumId,
    kind,
    favoritesOnly,
    newestFirst,
    createdFrom,
    createdTo,
  );
}
