import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/frame_theme.dart';
import '../../../../core/formatters.dart';
import '../../application/gallery_providers.dart';
import '../../domain/models.dart';

class MediaTile extends ConsumerWidget {
  const MediaTile({
    required this.query,
    required this.asset,
    required this.side,
    required this.onOpen,
    super.key,
  });

  final LibraryQuery query;
  final MediaAsset asset;
  final int side;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(
      selectionProvider(query).select((value) => value.active),
    );
    final selected = ref.watch(
      selectionProvider(query).select((value) => value.ids.contains(asset.id)),
    );
    final palette = context.palette;
    final provider = ref
        .watch(mediaImagesProvider)
        .thumbnail(asset.id, side: side);

    return GestureDetector(
      key: ValueKey('asset-${asset.id}'),
      onTap: () {
        if (selecting) {
          ref.read(selectionProvider(query).notifier).toggle(asset.id);
          return;
        }
        onOpen();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        final selection = ref.read(selectionProvider(query).notifier);
        if (selecting) {
          selection.toggle(asset.id);
        } else {
          selection.begin(asset.id);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Hero(
              tag: asset.id,
              child: Image(
                image: provider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return ColoredBox(color: palette.paperDeep);
                },
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: palette.paperDeep,
                    child: Icon(Icons.image_outlined, color: palette.muted),
                  );
                },
              ),
            ),
          ),
          if (asset.isVideo)
            Positioned(
              left: 6,
              bottom: 6,
              child: _Badge(label: formatDuration(asset.duration)),
            ),
          if (asset.isFavorite && !selecting)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.favorite, size: 16, color: Colors.white),
            ),
          if (selecting)
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? palette.accent : Colors.black38,
                  border: Border.all(color: Colors.white, width: 1.6),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
