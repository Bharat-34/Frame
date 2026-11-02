import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/formatters.dart';
import '../application/gallery_providers.dart';
import '../domain/models.dart';
import 'gallery_actions.dart';
import 'widgets/media_info_sheet.dart';

class ViewerArgs {
  const ViewerArgs({required this.query, required this.initialId});

  final LibraryQuery query;
  final String initialId;
}

class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({required this.args, super.key});

  final ViewerArgs args;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  late final PageController _controller;
  late int _index;
  bool _chrome = true;

  @override
  void initState() {
    super.initState();
    final assets =
        ref.read(assetsProvider(widget.args.query)).value?.assets ??
        const <MediaAsset>[];
    final found = assets.indexWhere(
      (asset) => asset.id == widget.args.initialId,
    );
    _index = found < 0 ? 0 : found;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.args.query;
    ref.listen(assetsProvider(query), (previous, next) {
      final assets = next.value?.assets;
      if (assets == null) return;
      if (assets.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
        return;
      }
      if (_index >= assets.length && _controller.hasClients) {
        _index = assets.length - 1;
        _controller.jumpToPage(_index);
      }
    });

    final listing = ref.watch(assetsProvider(query));
    final assets = listing.value?.assets ?? const <MediaAsset>[];
    final asset = assets.isEmpty
        ? null
        : assets[_index.clamp(0, assets.length - 1)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: assets.isEmpty
            ? const Center(
                child: Text(
                  'Nothing to show',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: assets.length,
                    onPageChanged: (index) {
                      setState(() => _index = index);
                      if (index >= assets.length - 4) {
                        ref.read(assetsProvider(query).notifier).loadMore();
                      }
                      _precache(index, assets);
                    },
                    itemBuilder: (context, index) {
                      final item = assets[index];
                      final hero =
                          item.id == widget.args.initialId && index == _index;
                      if (item.isVideo) {
                        return _VideoPane(
                          assetId: item.id,
                          active: index == _index,
                          onTap: _toggleChrome,
                        );
                      }
                      return _ZoomableImage(
                        assetId: item.id,
                        hero: hero,
                        onTap: _toggleChrome,
                      );
                    },
                  ),
                  _Chrome(
                    visible: _chrome,
                    title: asset == null
                        ? ''
                        : '${formatCount(_index + 1)} / ${formatCount(assets.length)}',
                    favorite: asset?.isFavorite ?? false,
                    onClose: () => Navigator.of(context).pop(),
                    onShare: asset == null
                        ? null
                        : () => shareAssets(context, ref, [asset.id]),
                    onFavorite: asset == null
                        ? null
                        : () => favoriteIds(context, ref, query, [
                            asset.id,
                          ], favorite: !asset.isFavorite),
                    onInfo: asset == null
                        ? null
                        : () => showMediaInfo(context, asset),
                    onDelete: asset == null
                        ? null
                        : () =>
                              confirmAndDelete(context, ref, query, [asset.id]),
                  ),
                ],
              ),
      ),
    );
  }

  void _toggleChrome() => setState(() => _chrome = !_chrome);

  void _precache(int index, List<MediaAsset> assets) {
    for (final neighbor in [index - 1, index + 1]) {
      if (neighbor < 0 || neighbor >= assets.length) continue;
      final asset = assets[neighbor];
      if (asset.isVideo) continue;
      precacheImage(ref.read(mediaImagesProvider).display(asset.id), context);
    }
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.visible,
    required this.title,
    required this.favorite,
    required this.onClose,
    required this.onShare,
    required this.onFavorite,
    required this.onInfo,
    required this.onDelete,
  });

  final bool visible;
  final String title;
  final bool favorite;
  final VoidCallback onClose;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final VoidCallback? onInfo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: NavigationToolbar(
                    leading: IconButton(
                      tooltip: 'Close',
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    middle: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ViewerAction(
                        icon: Icons.ios_share,
                        label: 'Share',
                        onPressed: onShare,
                      ),
                      _ViewerAction(
                        icon: favorite ? Icons.favorite : Icons.favorite_border,
                        label: favorite ? 'Saved' : 'Save',
                        onPressed: onFavorite,
                      ),
                      _ViewerAction(
                        icon: Icons.info_outline,
                        label: 'Info',
                        onPressed: onInfo,
                      ),
                      _ViewerAction(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends ConsumerStatefulWidget {
  const _ZoomableImage({
    required this.assetId,
    required this.hero,
    required this.onTap,
  });

  final String assetId;
  final bool hero;
  final VoidCallback onTap;

  @override
  ConsumerState<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends ConsumerState<_ZoomableImage> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hero && oldWidget.hero) {
      _transform.value = Matrix4.identity();
    }
  }

  void _zoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    final position = _doubleTap?.localPosition ?? Offset.zero;
    const scale = 2.6;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final image = Image(
      image: ref.watch(mediaImagesProvider).display(widget.assetId),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image_outlined, color: Colors.white54);
      },
    );
    final child = InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      child: Center(child: image),
    );
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTap = details,
      onDoubleTap: _zoom,
      child: widget.hero ? Hero(tag: widget.assetId, child: child) : child,
    );
  }
}

class _VideoPane extends ConsumerStatefulWidget {
  const _VideoPane({
    required this.assetId,
    required this.active,
    required this.onTap,
  });

  final String assetId;
  final bool active;
  final VoidCallback onTap;

  @override
  ConsumerState<_VideoPane> createState() => _VideoPaneState();
}

class _VideoPaneState extends ConsumerState<_VideoPane> {
  VideoPlayerController? _controller;
  bool _opening = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _open();
  }

  @override
  void didUpdateWidget(covariant _VideoPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _controller == null && !_opening) _open();
    if (!widget.active) _controller?.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    _opening = true;
    try {
      final path = await ref
          .read(mediaRepositoryProvider)
          .filePath(widget.assetId);
      if (!mounted) return;
      if (path == null) {
        setState(() => _failed = true);
        return;
      }
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      if (widget.active) await controller.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const Center(
        child: Text(
          'This video cannot be played.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 1
                  : controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.isPlaying) return const SizedBox.shrink();
              return IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => controller.play(),
                icon: const Icon(Icons.play_arrow, size: 36),
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 108,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final total = value.duration.inMilliseconds;
                final position = total == 0
                    ? 0.0
                    : value.position.inMilliseconds.clamp(0, total) / total;
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: position,
                    onChanged: total == 0
                        ? null
                        : (next) {
                            controller.seekTo(
                              Duration(milliseconds: (next * total).round()),
                            );
                          },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
