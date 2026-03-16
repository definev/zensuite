import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenquery/zenquery.dart';

void main() {
  group('InfinityQuery Tests', () {
    test('createInfinityQuery fetches first page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (_, cursor) async => [1, 2, 3],
        getNextCursor: (_, lastPage, allPages) => null,
      );

      final data = container.read(query);

      // Initial state
      expect(data.data.value, isEmpty);
      expect(container.read(data.loadState), isA<MutationIdle>());

      // Fetch first page
      await data.fetchNext();

      expect(data.data.value, [1, 2, 3]);
      expect(data.pages.value.length, 1);
    });

    test('createInfinityQuery fetches next page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (_, cursor) async {
          if (cursor == null) return [1, 2];
          return [3, 4];
        },
        getNextCursor:
            (_, lastPage, allPages) => allPages.length < 2 ? 1 : null,
      );

      final data = container.read(query);

      // Fetch first page
      await data.fetchNext();
      expect(data.data.value, [1, 2]);

      // Fetch next page
      await data.fetchNext();

      expect(data.data.value, [1, 2, 3, 4]);
      expect(data.pages.value.length, 2);
    });

    test('createInfinityQuery refresh resets data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (_, cursor) async => [1, 2, 3],
        getNextCursor: (_, lastPage, allPages) => null,
      );

      final data = container.read(query);

      await data.fetchNext();
      expect(data.data.value, [1, 2, 3]);

      await data.refresh();

      expect(data.data.value, [1, 2, 3]);
      // Verify it's a fresh load by ensuring pages count is 1 after refresh
      expect(data.pages.value.length, 1);
    });

    test('createInfinityQueryPersist fetches data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQueryPersist<int, int>(
        fetch: (_, cursor) async => [10, 20, 30],
        getNextCursor: (_, lastPage, allPages) => null,
      );

      final data = container.read(query);

      await data.fetchNext();

      expect(data.data.value, [10, 20, 30]);
      expect(data.pages.value.length, 1);
    });

    test('InfinityQuery.isLoading returns true during fetch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return [1, 2, 3];
        },
        getNextCursor: (_, lastPage, allPages) => null,
      );
      addTearDown(query.dispose);

      // Start fetching without awaiting
      final future = query.fetchNextPage(container);

      // Should be loading
      expect(query.isLoading(container), true);

      await future;

      // Should not be loading anymore
      expect(query.isLoading(container), false);
    });

    test('InfinityQuery.error returns error after failed fetch', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final testError = Exception('fetch failed');
      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async => throw testError,
        getNextCursor: (_, lastPage, allPages) => null,
      );
      addTearDown(query.dispose);

      try {
        await query.fetchNextPage(container);
      } catch (_) {}

      expect(query.error(container), testError);
    });

    test('fetchNextPage prevents duplicate calls when pending', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var fetchCount = 0;
      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async {
          fetchCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return [1, 2, 3];
        },
        getNextCursor: (_, lastPage, allPages) => null,
      );
      addTearDown(query.dispose);

      // Start two fetches simultaneously
      final future1 = query.fetchNextPage(container);
      final future2 = query.fetchNextPage(container);

      await Future.wait([future1, future2]);

      // Only one fetch should have occurred
      expect(fetchCount, 1);
    });

    test('fetchNextPage skips when no next cursor', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var fetchCount = 0;
      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async {
          fetchCount++;
          return [1, 2, 3];
        },
        getNextCursor: (_, lastPage, allPages) => null,
      );
      addTearDown(query.dispose);

      // First fetch
      await query.fetchNextPage(container);
      expect(fetchCount, 1);

      // Second fetch should be skipped (no next cursor)
      await query.fetchNextPage(container);
      expect(fetchCount, 1);
    });

    test('InfinityQuery.items returns flattened data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async => [1, 2, 3],
        getNextCursor: (_, lastPage, allPages) => null,
      );
      addTearDown(query.dispose);

      await query.fetchNextPage(container);

      expect(query.items, [1, 2, 3]);
    });

    test('InfinityQuery.refresh resets and reloads data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var fetchCount = 0;
      final query = InfinityQuery<int, int>(
        fetch: (_, cursor) async {
          fetchCount++;
          if (cursor == null) return [1, 2];
          return [3, 4];
        },
        getNextCursor:
            (_, lastPage, allPages) => allPages.length < 2 ? 1 : null,
      );
      addTearDown(query.dispose);

      // Fetch first page
      await query.fetchNextPage(container);
      expect(query.pages.value.length, 1);
      expect(fetchCount, 1);

      // Fetch second page
      await query.fetchNextPage(container);
      expect(query.pages.value.length, 2);
      expect(query.data.value, [1, 2, 3, 4]);
      expect(fetchCount, 2);

      // Refresh should reset to first page only
      await query.refresh(container);
      expect(query.pages.value.length, 1);
      expect(query.data.value, [1, 2]);
      expect(fetchCount, 3);
    });

    test('createInfinityQueryPersist refresh works correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var fetchCount = 0;
      final query = createInfinityQueryPersist<int, int>(
        fetch: (_, cursor) async {
          fetchCount++;
          return [fetchCount * 10];
        },
        getNextCursor: (_, lastPage, allPages) => null,
      );

      final data = container.read(query);

      await data.fetchNext();
      expect(data.data.value, [10]);

      await data.refresh();
      expect(data.data.value, [20]);
      expect(fetchCount, 2);
    });
    test('InfinityQuery refresh race condition regression', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final completer = Completer<void>();

      final query = createInfinityQuery<int, int>(
        fetch: (_, cursor) async {
          if (cursor == null) return [1];
          // Simulate slow fetch for second page
          await completer.future;
          return [2];
        },
        getNextCursor:
            (_, lastPage, allPages) => allPages.length < 2 ? 1 : null,
      );

      final data = container.read(query);

      // Initial fetch (Page 1)
      await data.fetchNext();
      expect(data.data.value, [1]);
      expect(data.pages.value.length, 1);

      // Start fetching Page 2
      final fetchFuture = data.fetchNext();

      // Check loading state
      expect(container.read(data.loadState), isA<MutationPending>());

      // Call refresh immediately while fetching
      await data.refresh();

      // Now let the fetch complete
      completer.complete();
      await fetchFuture;

      // If the bug exists, we have lost page 1 and started at page 2 (which is incorrect for a fresh list)
      // Correct behavior: refresh resets to empty and starts fetching page 1.
      // The pending "fetch page 2" completes but is ignored due to version mismatch.
      // Since refresh calls _fetchFirstPage, and that is async, it should eventually populate with [1].

      expect(data.data.value, [
        1,
      ], reason: 'Should contain Page 1 after refresh');
    });
  });
}
