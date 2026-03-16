import 'package:flutter/foundation.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart';

/// A function that fetches a list of items based on a cursor.
typedef FetchFunction<T, TCursor> =
    Future<List<T>> Function(MutationTransaction tsx, TCursor? cursor);

/// A function that determines the next cursor based on the last loaded page and all loaded pages.
///
/// Returns `null` if there are no more pages.
typedef NextCursorFunction<T, TCursor> =
    TCursor? Function(
      ProviderContainer container,
      List<T>? lastPage,
      List<List<T>> pages,
    );

/// Holds the state and actions for an infinite query.
class InfinityQueryData<T, C> {
  const InfinityQueryData({
    required this.fetchNext,
    required this.refresh,
    required this.pages,
    required this.data,
    required this.loadState,
  });

  /// Function to fetch the next page of data.
  final FutureCallback fetchNext;

  /// Function to refresh the data, clearing existing pages and fetching the first page again.
  final FutureCallback refresh;

  /// A notifier holding the list of pages.
  final ValueNotifier<List<List<T>>> pages;

  /// A notifier holding the flattened list of all items.
  final ValueNotifier<List<T>> data;

  /// The loading state of the query (e.g., pending, success, error).
  final Mutation<void> loadState;
}

/// A callback function that returns a Future.
typedef FutureCallback = Future<void> Function();

InfinityQueryData<T, TCursor> Function(Ref ref) infinityQueryFn<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => (ref) {
  final query = InfinityQuery<T, TCursor>(
    fetch: fetch,
    getNextCursor: getNextCursor,
  );
  ref.onDispose(query.dispose);
  Future.microtask(() => query.fetchNextPage(ref));

  return InfinityQueryData(
    fetchNext: () => query.fetchNextPage(ref),
    refresh: () => query.refresh(ref),
    pages: query.pages,
    data: query.data,
    loadState: query.loadState,
  );
};

/// Creates a [Provider] for an [InfinityQueryData] that automatically disposes when unused.
///
/// [fetch] is the function to fetch data for a given cursor.
/// [getNextCursor] determines the cursor for the next page.
Provider<InfinityQueryData<T, TCursor>> createInfinityQuery<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => Provider.autoDispose(
  infinityQueryFn<T, TCursor>(fetch: fetch, getNextCursor: getNextCursor),
);

/// Creates a [Provider] for an [InfinityQueryData] that persists its state.
///
/// [fetch] is the function to fetch data for a given cursor.
/// [getNextCursor] determines the cursor for the next page.
Provider<InfinityQueryData<T, TCursor>> createInfinityQueryPersist<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => Provider(
  infinityQueryFn<T, TCursor>(fetch: fetch, getNextCursor: getNextCursor),
);

/// Manages the state and logic for infinite pagination.
class InfinityQuery<T, TCursor> {
  InfinityQuery({
    required FetchFunction<T, TCursor> fetch,
    required NextCursorFunction<T, TCursor> getNextCursor,
  }) : _getNextCursor = getNextCursor,
       _fetch = fetch {
    pages.addListener(_updateData);
  }

  /// The loading state of the query.
  final Mutation<void> loadState = Mutation<void>();

  /// The flattened list of all items.
  final ValueNotifier<List<T>> data = ValueNotifier([]);

  /// The list of pages, where each page is a list of items.
  final ValueNotifier<List<List<T>>> pages = ValueNotifier([]);

  final FetchFunction<T, TCursor> _fetch;
  final NextCursorFunction<T, TCursor> _getNextCursor;

  /// Current flattened data items.
  List<T> get items => data.value;

  /// Whether currently loading more.
  bool isLoading(ProviderContainer container) =>
      container.read(loadState) is MutationPending;

  /// Returns the error object if the last fetch failed.
  Object? error(MutationTarget target) {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationError) {
      return loadState.error;
    }
    return null;
  }

  int _version = 0;

  /// Fetch the first page of data.
  Future<void> _fetchFirstPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    final startVersion = _version;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(tsx, null);
      if (startVersion != _version) return;
      pages.value = [result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      if (startVersion != _version) {
        // If version changed, we are not actually successfully loaded for the *current* version.
        // But the Mutation state itself is shared.
        // We arguably should reset it if we ignored the result?
        // Actually, if we ignored the result, the mutation success value is for the *old* fetch.
        // The refresh overwrites mutation state?
        // Refresh calls _fetchFirstPage -> loadState.run.
        // If we are pending, refresh waits?
        // Wait, refresh logic needs to be robust.
        return;
      }
      this.loadState.reset(target);
    }
  }

  /// Fetch the next page of data.
  Future<void> fetchNextPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    // If no pages yet, fetch first page instead
    if (pages.value.isEmpty) {
      return _fetchFirstPage(target);
    }

    final nextCursor = _getNextCursor(
      target.container,
      pages.value.last,
      pages.value,
    );
    if (nextCursor == null) return;

    final startVersion = _version;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(tsx, nextCursor);
      if (startVersion != _version) return;
      pages.value = [...pages.value, result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      if (startVersion != _version) return;
      this.loadState.reset(target);
    }
  }

  /// Refresh and reload from the beginning.
  Future<void> refresh(MutationTarget target) async {
    _version++;
    pages.value = [];
    loadState.reset(target);
    await _fetchFirstPage(target);
  }

  /// Disposes the notifiers.
  void dispose() {
    pages.removeListener(_updateData);
    pages.dispose();
    data.dispose();
  }

  void _updateData() {
    data.value = pages.value.expand((page) => page).toList();
  }
}
