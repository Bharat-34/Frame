import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../application/gallery_providers.dart';
import '../domain/models.dart';

Future<void> shareAssets(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  if (ids.length > 40) {
    _message(context, 'Select 40 items or fewer to share at once.');
    return;
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  var dialogOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );
  void closeDialog() {
    if (!dialogOpen || !context.mounted) return;
    dialogOpen = false;
    navigator.pop();
  }

  try {
    final repository = ref.read(mediaRepositoryProvider);
    final files = <XFile>[];
    for (final id in ids) {
      final path = await repository.filePath(id);
      if (path != null) files.add(XFile(path));
    }
    closeDialog();
    if (files.isEmpty) {
      if (context.mounted) {
        _message(context, 'Those files could not be prepared for sharing.');
      }
      return;
    }
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(
      ShareParams(files: files, sharePositionOrigin: origin),
    );
  } on GalleryFailure catch (error) {
    closeDialog();
    if (context.mounted) _message(context, error.message);
  } catch (_) {
    closeDialog();
    if (context.mounted) {
      _message(context, 'Sharing did not finish.');
    }
  }
}

Future<bool> confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  LibraryQuery query,
  List<String> ids,
) async {
  if (ids.isEmpty) return false;
  final count = ids.length;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(count == 1 ? 'Delete this item?' : 'Delete $count items?'),
        content: const Text(
          'This removes them from the device. Android will ask you to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    final deleted = await ref
        .read(assetsProvider(query).notifier)
        .deleteIds(ids);
    if (!deleted && context.mounted) {
      _message(context, 'Nothing was deleted.');
    }
    return deleted;
  } on GalleryFailure catch (error) {
    if (context.mounted) _message(context, error.message);
    return false;
  }
}

Future<void> favoriteIds(
  BuildContext context,
  WidgetRef ref,
  LibraryQuery query,
  List<String> ids, {
  required bool favorite,
}) async {
  if (ids.isEmpty) return;
  try {
    await ref.read(assetsProvider(query).notifier).setFavorites(ids, favorite);
  } on GalleryFailure catch (error) {
    if (context.mounted) _message(context, error.message);
  }
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
