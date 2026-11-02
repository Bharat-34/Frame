import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import 'media_browser.dart';
import 'viewer_page.dart';

class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaBrowser(
      title: 'Photos',
      baseQuery: const LibraryQuery(),
      onOpen: (query, id) {
        context.push(
          '/viewer',
          extra: ViewerArgs(query: query, initialId: id),
        );
      },
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaBrowser(
      title: 'Saved',
      baseQuery: const LibraryQuery(favoritesOnly: true),
      onOpen: (query, id) {
        context.push(
          '/viewer',
          extra: ViewerArgs(query: query, initialId: id),
        );
      },
    );
  }
}

class AlbumPage extends StatelessWidget {
  const AlbumPage({required this.album, super.key});

  final MediaAlbum album;

  @override
  Widget build(BuildContext context) {
    return MediaBrowser(
      title: album.name,
      showBack: true,
      baseQuery: LibraryQuery(albumId: album.id),
      onOpen: (query, id) {
        context.push(
          '/viewer',
          extra: ViewerArgs(query: query, initialId: id),
        );
      },
    );
  }
}
