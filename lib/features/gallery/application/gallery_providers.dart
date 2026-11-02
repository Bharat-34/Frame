import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/photo_manager_media_repository.dart';
import '../domain/media_repository.dart';
import '../domain/models.dart';

final photoRepositoryProvider = Provider<PhotoManagerMediaRepository>((ref) {
  final repository = PhotoManagerMediaRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => ref.watch(photoRepositoryProvider),
);

final mediaImagesProvider = Provider<MediaImages>(
  (ref) => ref.watch(photoRepositoryProvider),
);

/// Keeps every open library list in sync after a delete or favorite.
class LibraryCoordinator {
  final Map<Object, Future<void> Function()> _refreshers = {};

  void register(Object key, Future<void> Function() refresh) {
    _refreshers[key] = refresh;
  }

  void unregister(Object key) {
    _refreshers.remove(key);
  }

  Future<void> refreshAll() async {
    final jobs = List<Future<void> Function()>.of(_refreshers.values);
    await Future.wait(
      jobs.map((job) async {
        try {
          await job();
        } catch (_) {
          // Each screen keeps its own error state.
        }
      }),
    );
  }
}

final libraryCoordinatorProvider = Provider<LibraryCoordinator>((ref) {
  return LibraryCoordinator();
});

class AssetListing {
  const AssetListing({
    required this.assets,
    required this.total,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<MediaAsset> assets;
  final int total;
  final bool hasMore;
  final bool loadingMore;

  AssetListing copyWith({
    List<MediaAsset>? assets,
    int? total,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return AssetListing(
      assets: assets ?? this.assets,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

final assetsProvider =
    AsyncNotifierProvider.family<AssetsController, AssetListing, LibraryQuery>(
      AssetsController.new,
    );

class AssetsController extends AsyncNotifier<AssetListing> {
  AssetsController(this.query);

  final LibraryQuery query;
  static const pageSize = 60;

  int _generation = 0;
  int _nextPage = 1;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _registered = false;

  @override
  Future<AssetListing> build() {
    _generation += 1;
    _nextPage = 1;
    _loadingMore = false;
    _loadMoreFailed = false;
    _register();
    return _fetch(0);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _loadingMore = false;
    _loadMoreFailed = false;
    ref.read(mediaRepositoryProvider).invalidatePaths();
    final previous = state.value;
    try {
      final listing = await _fetch(0);
      if (generation != _generation) return;
      _nextPage = 1;
      state = AsyncData(listing);
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      if (previous != null) {
        state = AsyncData(previous.copyWith(loadingMore: false));
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || _loadMoreFailed) return;
    final current = state.value;
    if (current == null || !current.hasMore) return;
    _loadingMore = true;
    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _fetch(_nextPage);
      if (generation != _generation) return;
      final latest = state.value ?? current;
      _nextPage += 1;
      state = AsyncData(
        latest.copyWith(
          assets: [...latest.assets, ...page.assets],
          total: page.total,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      _loadMoreFailed = true;
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(loadingMore: false));
      }
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }

  void allowLoadMoreRetry() => _loadMoreFailed = false;

  Future<bool> deleteIds(List<String> ids) async {
    final deleted = await ref.read(mediaRepositoryProvider).delete(ids);
    if (deleted.isEmpty) return false;
    await ref.read(libraryCoordinatorProvider).refreshAll();
    return true;
  }

  Future<void> setFavorites(List<String> ids, bool favorite) async {
    final repository = ref.read(mediaRepositoryProvider);
    for (final id in ids) {
      await repository.setFavorite(id, favorite);
    }
    await ref.read(libraryCoordinatorProvider).refreshAll();
  }

  void _register() {
    if (_registered) return;
    _registered = true;
    final coordinator = ref.read(libraryCoordinatorProvider);
    coordinator.register(query, refresh);
    ref.onDispose(() {
      coordinator.unregister(query);
      _registered = false;
    });
  }

  Future<AssetListing> _fetch(int page) async {
    final result = await ref
        .read(mediaRepositoryProvider)
        .page(query: query, page: page, size: pageSize);
    return AssetListing(
      assets: result.items,
      total: result.total,
      hasMore: result.hasMore,
    );
  }
}

final albumsProvider =
    AsyncNotifierProvider<AlbumsController, List<MediaAlbum>>(
      AlbumsController.new,
    );

class AlbumsController extends AsyncNotifier<List<MediaAlbum>> {
  bool _registered = false;

  @override
  Future<List<MediaAlbum>> build() {
    _register();
    return ref.read(mediaRepositoryProvider).albums();
  }

  Future<void> refresh() async {
    final previous = state.value;
    try {
      final albums = await ref.read(mediaRepositoryProvider).albums();
      state = AsyncData(albums);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  void _register() {
    if (_registered) return;
    _registered = true;
    final coordinator = ref.read(libraryCoordinatorProvider);
    coordinator.register('albums', refresh);
    ref.onDispose(() {
      coordinator.unregister('albums');
      _registered = false;
    });
  }
}

final accessProvider = AsyncNotifierProvider<AccessController, LibraryAccess>(
  AccessController.new,
);

class AccessController extends AsyncNotifier<LibraryAccess> {
  @override
  Future<LibraryAccess> build() {
    return ref.read(mediaRepositoryProvider).currentAccess();
  }

  Future<void> request() async {
    final next = await ref.read(mediaRepositoryProvider).requestAccess();
    state = AsyncData(next);
  }

  Future<void> refresh() async {
    final previous = state.value;
    try {
      final next = await ref.read(mediaRepositoryProvider).currentAccess();
      state = AsyncData(next);
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
    }
  }
}

class SelectionState {
  const SelectionState({this.active = false, this.ids = const {}});

  final bool active;
  final Set<String> ids;

  int get count => ids.length;

  SelectionState copyWith({bool? active, Set<String>? ids}) {
    return SelectionState(active: active ?? this.active, ids: ids ?? this.ids);
  }
}

final selectionProvider =
    NotifierProvider.family<SelectionController, SelectionState, LibraryQuery>(
      SelectionController.new,
    );

class SelectionController extends Notifier<SelectionState> {
  SelectionController(this.query);

  final LibraryQuery query;

  @override
  SelectionState build() => const SelectionState();

  void begin(String id) {
    state = SelectionState(active: true, ids: {id});
  }

  void toggle(String id) {
    if (!state.active) return;
    final next = Set<String>.of(state.ids);
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(ids: next);
  }

  void clear() => state = const SelectionState();

  void replace(Iterable<String> ids) {
    state = SelectionState(active: true, ids: ids.toSet());
  }
}

final columnCountProvider = NotifierProvider<ColumnCountController, int>(
  ColumnCountController.new,
);

class ColumnCountController extends Notifier<int> {
  @override
  int build() => 3;

  void setCount(int count) => state = count;
}
