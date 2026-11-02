import 'package:flutter/painting.dart';

import 'models.dart';

/// Reads and changes the device library.
///
/// The interface stays free of PhotoManager types so screens can be tested
/// with a fake, and a different source can be added later without rewriting UI.
abstract class MediaRepository {
  Future<LibraryAccess> currentAccess();

  Future<LibraryAccess> requestAccess();

  Future<void> openSystemSettings();

  /// Re-opens the system picker used for limited photo access.
  Future<void> manageLimitedAccess();

  Future<List<MediaAlbum>> albums();

  Future<MediaPage> page({
    required LibraryQuery query,
    required int page,
    required int size,
  });

  Future<void> setFavorite(String id, bool favorite);

  /// Ids the platform actually deleted. Empty when the person cancels.
  Future<List<String>> delete(List<String> ids);

  Future<String?> filePath(String id);

  Future<MediaDetails> details(String id);

  /// Drops cached album cursors so the next read sees new files.
  void invalidatePaths();
}

/// Thumbnail and viewer images for assets the repository has already loaded.
abstract class MediaImages {
  ImageProvider thumbnail(String id, {required int side});

  ImageProvider display(String id);
}
