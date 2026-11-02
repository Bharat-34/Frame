import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frame/app/theme/frame_theme.dart';
import 'package:frame/features/gallery/application/gallery_providers.dart';
import 'package:frame/features/gallery/domain/models.dart';
import 'package:frame/features/gallery/presentation/media_browser.dart';

import 'support/fake_media_repository.dart';

void main() {
  testWidgets('shows days, filters videos, and starts a selection', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = FakeMediaRepository([
      MediaAsset(
        id: 'today-video',
        kind: MediaKind.video,
        width: 100,
        height: 100,
        duration: const Duration(seconds: 12),
        createdAt: now,
        isFavorite: false,
      ),
      MediaAsset(
        id: 'yesterday-photo',
        kind: MediaKind.image,
        width: 100,
        height: 100,
        duration: Duration.zero,
        createdAt: now.subtract(const Duration(days: 1)),
        isFavorite: false,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(repository),
          mediaImagesProvider.overrideWithValue(FakeMediaImages()),
          accessProvider.overrideWith(GrantedAccess.new),
        ],
        child: MaterialApp(
          theme: FrameTheme.light,
          home: MediaBrowser(
            title: 'Photos',
            baseQuery: const LibraryQuery(),
            onOpen: (query, id) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);

    await tester.tap(find.text('Videos'));
    await tester.pumpAndSettle();

    expect(find.text('Yesterday'), findsNothing);
    expect(find.byKey(const ValueKey('asset-today-video')), findsOneWidget);

    await tester.longPress(find.byKey(const ValueKey('asset-today-video')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });
}

class GrantedAccess extends AccessController {
  @override
  Future<LibraryAccess> build() async => LibraryAccess.granted;
}
