import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/frame_theme.dart';
import '../../../core/formatters.dart';
import '../application/gallery_providers.dart';
import '../domain/date_query.dart';
import '../domain/day_group.dart';
import '../domain/models.dart';
import 'gallery_actions.dart';
import 'widgets/day_header.dart';
import 'widgets/media_tile.dart';

class MediaBrowser extends ConsumerStatefulWidget {
  const MediaBrowser({
    required this.title,
    required this.baseQuery,
    required this.onOpen,
    this.showBack = false,
    super.key,
  });

  final String title;
  final LibraryQuery baseQuery;
  final void Function(LibraryQuery query, String assetId) onOpen;
  final bool showBack;

  @override
  ConsumerState<MediaBrowser> createState() => _MediaBrowserState();
}

class _MediaBrowserState extends ConsumerState<MediaBrowser> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;
  MediaKind? _kind;
  bool _newestFirst = true;
  DateWindow? _window;
  bool _searchMiss = false;
  LibraryQuery? _activeQuery;

  LibraryQuery get _query {
    return widget.baseQuery.copyWith(
      kind: _kind,
      clearKind: _kind == null,
      newestFirst: _newestFirst,
      createdFrom: _window?.start,
      createdTo: _window?.end,
      clearCreated: _window == null,
    );
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final query = _activeQuery;
    if (!mounted || query == null || !_scroll.hasClients) return;
    final position = _scroll.position;
    final nearEnd = position.pixels >= position.maxScrollExtent - 700;
    final notifier = ref.read(assetsProvider(query).notifier);
    if (!nearEnd) {
      notifier.allowLoadMoreRetry();
      return;
    }
    unawaited(notifier.loadMore());
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final text = _search.text;
      final window = parseDateQuery(text, now: DateTime.now());
      setState(() {
        _window = window;
        _searchMiss = text.trim().isNotEmpty && window == null;
      });
      _jumpTop();
    });
  }

  void _jumpTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    _activeQuery = query;
    final listing = ref.watch(assetsProvider(query));
    final selection = ref.watch(selectionProvider(query));
    final columns = ref.watch(columnCountProvider);
    final access = ref.watch(accessProvider);
    final palette = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom + 108;

    return Scaffold(
      body: PopScope(
        canPop: !selection.active,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && selection.active) {
            ref.read(selectionProvider(query).notifier).clear();
          }
        },
        child: Stack(
          children: [
            RefreshIndicator(
              color: palette.accent,
              onRefresh: () =>
                  ref.read(assetsProvider(query).notifier).refresh(),
              child: CustomScrollView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    leading: selection.active
                        ? IconButton(
                            tooltip: 'Cancel selection',
                            onPressed: () => ref
                                .read(selectionProvider(query).notifier)
                                .clear(),
                            icon: const Icon(Icons.close),
                          )
                        : widget.showBack
                        ? IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          )
                        : null,
                    title: Text(
                      selection.active
                          ? '${formatCount(selection.count)} selected'
                          : widget.title,
                    ),
                    actions: [
                      if (selection.active)
                        TextButton(
                          onPressed: () {
                            final assets = listing.value?.assets ?? const [];
                            ref
                                .read(selectionProvider(query).notifier)
                                .replace(assets.map((asset) => asset.id));
                          },
                          child: const Text('All'),
                        )
                      else
                        PopupMenuButton<String>(
                          tooltip: 'View options',
                          onSelected: (value) {
                            if (value == '3' || value == '4') {
                              ref
                                  .read(columnCountProvider.notifier)
                                  .setCount(int.parse(value));
                              return;
                            }
                            setState(() => _newestFirst = value == 'newest');
                            _jumpTop();
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: '3',
                              checked: columns == 3,
                              child: const Text('3 columns'),
                            ),
                            CheckedPopupMenuItem(
                              value: '4',
                              checked: columns == 4,
                              child: const Text('4 columns'),
                            ),
                            const PopupMenuDivider(),
                            CheckedPopupMenuItem(
                              value: 'newest',
                              checked: _newestFirst,
                              child: const Text('Newest first'),
                            ),
                            CheckedPopupMenuItem(
                              value: 'oldest',
                              checked: !_newestFirst,
                              child: const Text('Oldest first'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SearchField(controller: _search),
                          if (_searchMiss)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                'Try Today, October, or 2024.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _KindFilter(
                            kind: _kind,
                            onChanged: (kind) {
                              setState(() => _kind = kind);
                              _jumpTop();
                            },
                          ),
                          if (access.value?.isLimited ?? false) ...[
                            const SizedBox(height: 12),
                            _LimitedBanner(
                              onManage: () async {
                                await ref
                                    .read(mediaRepositoryProvider)
                                    .manageLimitedAccess();
                                if (!context.mounted) return;
                                await ref
                                    .read(accessProvider.notifier)
                                    .refresh();
                                await ref
                                    .read(libraryCoordinatorProvider)
                                    .refreshAll();
                              },
                            ),
                          ],
                          if (listing.value case final loaded?)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, left: 4),
                              child: Text(
                                '${formatCount(loaded.total)} ${loaded.total == 1 ? 'item' : 'items'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ..._body(context, listing, query, columns, bottom),
                ],
              ),
            ),
            if (selection.active)
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom - 8,
                child: _SelectionBar(
                  onShare: () =>
                      shareAssets(context, ref, selection.ids.toList()),
                  onFavorite: () => _favoriteSelected(query, selection),
                  onDelete: () async {
                    final deleted = await confirmAndDelete(
                      context,
                      ref,
                      query,
                      selection.ids.toList(),
                    );
                    if (deleted && context.mounted) {
                      ref.read(selectionProvider(query).notifier).clear();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _favoriteSelected(
    LibraryQuery query,
    SelectionState selection,
  ) async {
    final assets = ref.read(assetsProvider(query)).value?.assets ?? [];
    final selected = assets.where((asset) => selection.ids.contains(asset.id));
    final makeFavorite = selected.any((asset) => !asset.isFavorite);
    await favoriteIds(
      context,
      ref,
      query,
      selection.ids.toList(),
      favorite: makeFavorite,
    );
  }

  List<Widget> _body(
    BuildContext context,
    AsyncValue<AssetListing> listing,
    LibraryQuery query,
    int columns,
    double bottom,
  ) {
    return listing.when(
      skipLoadingOnReload: true,
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          child: _Message(
            title: 'The library could not be opened',
            body: error is GalleryFailure
                ? error.message
                : 'Check photo access and try again.',
            action: 'Try again',
            onPressed: () => ref.invalidate(assetsProvider(query)),
          ),
        ),
      ],
      data: (loaded) {
        if (loaded.assets.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Message(
                title: widget.baseQuery.favoritesOnly
                    ? 'No saved favorites'
                    : 'Nothing here yet',
                body: widget.baseQuery.favoritesOnly
                    ? 'Open a photo and tap the heart to keep it in Saved.'
                    : 'Photos and videos you take will show up in this grid.',
              ),
            ),
          ];
        }
        final groups = groupAssetsByDay(
          loaded.assets,
          newestFirst: query.newestFirst,
        );
        final width = MediaQuery.sizeOf(context).width;
        final side = (width / columns * MediaQuery.devicePixelRatioOf(context))
            .round();
        return [
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: DayHeaderDelegate(
                    day: group.day,
                    count: group.assets.length,
                  ),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final asset = group.assets[index];
                    return MediaTile(
                      query: query,
                      asset: asset,
                      side: side,
                      onOpen: () => widget.onOpen(query, asset.id),
                    );
                  }, childCount: group.assets.length),
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 18, 0, bottom),
              child: loaded.loadingMore
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox(height: 8),
            ),
          ),
        ];
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search a day, month, or year',
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search, color: palette.muted),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            if (controller.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear search',
              onPressed: controller.clear,
              icon: Icon(Icons.close, color: palette.muted),
            );
          },
        ),
        filled: true,
        fillColor: palette.paperDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({required this.kind, required this.onChanged});

  final MediaKind? kind;
  final ValueChanged<MediaKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'All',
          selected: kind == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Photos',
          selected: kind == MediaKind.image,
          onTap: () => onChanged(MediaKind.image),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Videos',
          selected: kind == MediaKind.video,
          onTap: () => onChanged(MediaKind.video),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.ink : palette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? palette.paper : palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitedBanner extends StatelessWidget {
  const _LimitedBanner({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Showing only the photos you selected.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.ink),
              ),
            ),
            TextButton(onPressed: onManage, child: const Text('Manage')),
          ],
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Action(icon: Icons.ios_share, label: 'Share', onPressed: onShare),
            _Action(
              icon: Icons.favorite_border,
              label: 'Save',
              onPressed: onFavorite,
            ),
            _Action(
              icon: Icons.delete_outline,
              label: 'Delete',
              onPressed: onDelete,
              color: palette.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.palette.ink;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: ink),
      label: Text(label, style: TextStyle(color: ink)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    this.action,
    this.onPressed,
  });

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.palette.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
