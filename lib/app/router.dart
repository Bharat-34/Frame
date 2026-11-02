import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/gallery/domain/models.dart';
import '../features/gallery/presentation/albums_page.dart';
import '../features/gallery/presentation/gallery_shell.dart';
import '../features/gallery/presentation/library_pages.dart';
import '../features/gallery/presentation/viewer_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final frameRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/photos',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return GalleryShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/photos',
              builder: (context, state) => const PhotosPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/albums',
              builder: (context, state) => const AlbumsPage(),
              routes: [
                GoRoute(
                  path: 'open',
                  builder: (context, state) {
                    final album = state.extra;
                    if (album is! MediaAlbum) {
                      return const AlbumsPage();
                    }
                    return AlbumPage(album: album);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/viewer',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: extra is ViewerArgs
              ? ViewerPage(args: extra)
              : const Scaffold(backgroundColor: Colors.black),
          transitionsBuilder: (context, animation, secondary, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ],
);
