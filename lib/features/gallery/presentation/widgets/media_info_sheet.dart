import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/frame_theme.dart';
import '../../../../core/formatters.dart';
import '../../application/gallery_providers.dart';
import '../../domain/models.dart';

Future<void> showMediaInfo(BuildContext context, MediaAsset asset) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    builder: (context) => MediaInfoSheet(asset: asset),
  );
}

class MediaInfoSheet extends ConsumerStatefulWidget {
  const MediaInfoSheet({required this.asset, super.key});

  final MediaAsset asset;

  @override
  ConsumerState<MediaInfoSheet> createState() => _MediaInfoSheetState();
}

class _MediaInfoSheetState extends ConsumerState<MediaInfoSheet> {
  late final Future<MediaDetails> _details = ref
      .read(mediaRepositoryProvider)
      .details(widget.asset.id);

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: FutureBuilder<MediaDetails>(
          future: _details,
          builder: (context, snapshot) {
            final details = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _Row(label: 'Taken', value: formatWhen(asset.createdAt)),
                _Row(label: 'Type', value: asset.isVideo ? 'Video' : 'Photo'),
                if (asset.width > 0 && asset.height > 0)
                  _Row(
                    label: 'Resolution',
                    value: '${asset.width} × ${asset.height}',
                  ),
                if (asset.isVideo)
                  _Row(
                    label: 'Duration',
                    value: formatDuration(asset.duration),
                  ),
                _Row(
                  label: 'Size',
                  value: details?.byteSize == null
                      ? (snapshot.hasError ? 'Unavailable' : '…')
                      : formatBytes(details!.byteSize!),
                ),
                _Row(
                  label: 'Name',
                  value:
                      details?.title ?? (snapshot.hasError ? 'Untitled' : '…'),
                ),
                if (details?.mimeType != null)
                  _Row(label: 'Format', value: details!.mimeType!),
                if (asset.latitude != null && asset.longitude != null)
                  _Row(
                    label: 'Location',
                    value:
                        '${asset.latitude!.toStringAsFixed(4)}, ${asset.longitude!.toStringAsFixed(4)}',
                  ),
                const SizedBox(height: 8),
                Text(
                  'Stored on this device',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
