import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_state.dart';

import '../../../../helpers/fake_connectivity_service.dart';
import '../../../../helpers/fake_search_repository.dart';

void main() {
  const debounce = SearchNotifier.debounceDuration;

  late FakeSearchRepository repository;
  late FakeConnectivityService connectivity;
  late ProviderContainer container;

  void setUpContainer({bool honorCancellation = true}) {
    repository = FakeSearchRepository(honorCancellation: honorCancellation);
    connectivity = FakeConnectivityService();
    container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repository),
        connectivityOverride(connectivity),
      ],
    );
    container.listen(searchProvider, (_, _) {});
  }

  SearchNotifier notifier() => container.read(searchProvider.notifier);
  SearchState state() => container.read(searchProvider);

  test('starts idle', () {
    fakeAsync((async) {
      setUpContainer();

      expect(state(), isA<SearchIdle>());
      container.dispose();
    });
  });

  test('debounces typing and only searches the final query', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('f');
      async.elapse(const Duration(milliseconds: 100));
      notifier().onQueryChanged('fl');
      async.elapse(const Duration(milliseconds: 100));
      notifier().onQueryChanged('flu');
      async.elapse(debounce - const Duration(milliseconds: 1));

      expect(repository.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 1));

      expect(repository.calls.map((c) => c.query), ['flu']);
      expect(repository.calls.single.page, 1);
      container.dispose();
    });
  });

  test('emits loading then success', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(debounce);

      expect(state(), isA<SearchLoading>());
      expect((state() as SearchLoading).query, 'octo');

      repository.succeed('octo', count: 2, total: 2);
      async.flushMicrotasks();

      final success = state() as SearchSuccess;
      expect(success.query, 'octo');
      expect(success.users.map((u) => u.login), ['octo0', 'octo1']);
      expect(success.totalCount, 2);
      expect(success.hasMore, isFalse);
      container.dispose();
    });
  });

  test('emits empty when no users match', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('zzzz');
      async.elapse(debounce);
      repository.succeed('zzzz', count: 0, total: 0);
      async.flushMicrotasks();

      expect(state(), isA<SearchEmpty>());
      expect((state() as SearchEmpty).query, 'zzzz');
      container.dispose();
    });
  });

  test('emits error with the failure', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(debounce);
      repository.fail('octo', const RateLimitFailure());
      async.flushMicrotasks();

      final error = state() as SearchError;
      expect(error.query, 'octo');
      expect(error.failure, isA<RateLimitFailure>());
      container.dispose();
    });
  });

  test('cancels the previous request when a new query starts', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('a');
      async.elapse(debounce);
      notifier().onQueryChanged('ab');
      async.elapse(debounce);

      expect(repository.calls.first.token!.isCancelled, isTrue);
      expect(repository.calls.last.token!.isCancelled, isFalse);
      container.dispose();
    });
  });

  test('ignores a stale response that arrives after a newer one', () {
    fakeAsync((async) {
      setUpContainer(honorCancellation: false);

      notifier().onQueryChanged('a');
      async.elapse(debounce);
      notifier().onQueryChanged('ab');
      async.elapse(debounce);

      repository.succeed('ab', count: 1, total: 1);
      async.flushMicrotasks();
      repository.succeed('a', count: 5, total: 5);
      async.flushMicrotasks();

      final success = state() as SearchSuccess;
      expect(success.query, 'ab');
      expect(success.users, hasLength(1));
      container.dispose();
    });
  });

  test('ignores a stale error that arrives after a newer query', () {
    fakeAsync((async) {
      setUpContainer(honorCancellation: false);

      notifier().onQueryChanged('a');
      async.elapse(debounce);
      notifier().onQueryChanged('ab');
      async.elapse(debounce);

      repository.fail('a', const NetworkFailure());
      async.flushMicrotasks();

      expect(state(), isA<SearchLoading>());
      container.dispose();
    });
  });

  test('clearing the query returns to idle and cancels in-flight work', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(debounce);
      notifier().onQueryChanged('');
      async.flushMicrotasks();

      expect(state(), isA<SearchIdle>());
      expect(repository.calls.single.token!.isCancelled, isTrue);
      container.dispose();
    });
  });

  test('clearing before the debounce fires never hits the repository', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(const Duration(milliseconds: 100));
      notifier().onQueryChanged('   ');
      async.elapse(debounce * 2);

      expect(repository.calls, isEmpty);
      expect(state(), isA<SearchIdle>());
      container.dispose();
    });
  });

  test('trims input and skips a search for an unchanged query', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(debounce);
      notifier().onQueryChanged('  octo  ');
      async.elapse(debounce);

      expect(repository.calls.map((c) => c.query), ['octo']);
      container.dispose();
    });
  });

  test('submit searches immediately without waiting for the debounce', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('oc');
      notifier().submit('octo');
      async.flushMicrotasks();

      expect(repository.calls.map((c) => c.query), ['octo']);
      expect(state(), isA<SearchLoading>());

      async.elapse(debounce * 2);
      expect(repository.calls, hasLength(1));
      container.dispose();
    });
  });

  test('retry re-runs the last query after an error', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      async.elapse(debounce);
      repository.fail('octo', const NetworkFailure());
      async.flushMicrotasks();

      notifier().retry();
      async.flushMicrotasks();
      expect(state(), isA<SearchLoading>());

      repository.succeed('octo');
      async.flushMicrotasks();

      expect(state(), isA<SearchSuccess>());
      expect(repository.calls, hasLength(2));
      container.dispose();
    });
  });

  test('disposing the container cancels a pending debounce', () {
    fakeAsync((async) {
      setUpContainer();

      notifier().onQueryChanged('octo');
      container.dispose();
      async.elapse(debounce * 2);

      expect(repository.calls, isEmpty);
    });
  });

  group('pagination', () {
    SearchSuccess success() => state() as SearchSuccess;

    void searchFirstPage({int total = 100}) {
      notifier().submit('octo');
      repository.succeed('octo', count: 30, total: total);
    }

    test('first page exposes hasMore when more results exist', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        expect(success().page, 1);
        expect(success().users, hasLength(30));
        expect(success().hasMore, isTrue);
        container.dispose();
      });
    });

    test('loadMore requests the next page and appends results', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        expect(success().isLoadingMore, isTrue);
        expect(repository.calls.last.page, 2);
        expect(repository.calls.last.perPage, SearchNotifier.perPage);

        repository.succeed('octo', page: 2, count: 30, total: 100);
        async.flushMicrotasks();

        expect(success().page, 2);
        expect(success().users, hasLength(60));
        expect(success().users[30].id, 30);
        expect(success().isLoadingMore, isFalse);
        expect(success().hasMore, isTrue);
        container.dispose();
      });
    });

    test('stops when the last page is reached', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage(total: 45);
        async.flushMicrotasks();

        notifier().loadMore();
        repository.succeed('octo', page: 2, count: 15, total: 45);
        async.flushMicrotasks();

        expect(success().hasMore, isFalse);
        expect(success().users, hasLength(45));

        notifier().loadMore();
        expect(repository.calls, hasLength(2));
        container.dispose();
      });
    });

    test('ignores loadMore while a page is already loading', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        notifier().loadMore();
        notifier().loadMore();

        expect(repository.calls.where((c) => c.page == 2), hasLength(1));
        container.dispose();
      });
    });

    test('drops duplicate users that shift between pages', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        repository.succeed('octo', page: 2, count: 30, total: 100, firstId: 25);
        async.flushMicrotasks();

        final ids = success().users.map((u) => u.id).toList();
        expect(ids, hasLength(55));
        expect(ids.toSet(), hasLength(55));
        container.dispose();
      });
    });

    test('load more failure keeps existing results and blocks auto retry', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        repository.fail('octo', const NetworkFailure(), page: 2);
        async.flushMicrotasks();

        expect(success().users, hasLength(30));
        expect(success().isLoadingMore, isFalse);
        expect(success().loadMoreFailure, isA<NetworkFailure>());

        notifier().loadMore();
        expect(repository.calls, hasLength(2));
        container.dispose();
      });
    });

    test('retryLoadMore clears the failure and loads the page again', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        repository.fail('octo', const TimeoutFailure(), page: 2);
        async.flushMicrotasks();

        notifier().retryLoadMore();
        expect(success().loadMoreFailure, isNull);
        expect(success().isLoadingMore, isTrue);

        repository.succeed('octo', page: 2, count: 30, total: 100);
        async.flushMicrotasks();

        expect(success().users, hasLength(60));
        expect(repository.calls.where((c) => c.page == 2), hasLength(2));
        container.dispose();
      });
    });

    test('a new query cancels an in-flight page load', () {
      fakeAsync((async) {
        setUpContainer(honorCancellation: false);
        searchFirstPage();
        async.flushMicrotasks();

        notifier().loadMore();
        final pageTwoToken = repository.calls.last.token!;
        notifier().submit('hubot');
        repository.succeed('octo', page: 2, count: 30, total: 100);
        async.flushMicrotasks();

        expect(pageTwoToken.isCancelled, isTrue);
        expect(state(), isA<SearchLoading>());
        expect((state() as SearchLoading).query, 'hubot');
        container.dispose();
      });
    });

    test('loadMore is skipped while a new query is waiting on debounce', () {
      fakeAsync((async) {
        setUpContainer();
        searchFirstPage();
        async.flushMicrotasks();

        notifier().onQueryChanged('octocat');
        notifier().loadMore();

        expect(repository.calls, hasLength(1));
        container.dispose();
      });
    });

    test('marks results as capped when GitHub has more than 1000', () {
      fakeAsync((async) {
        setUpContainer();
        notifier().submit('a');
        repository.succeed('a', count: 30, total: 1000000);
        async.flushMicrotasks();

        expect(success().isCapped, isFalse);

        for (var page = 2; page <= 34; page++) {
          notifier().loadMore();
          repository.succeed(
            'a',
            page: page,
            count: page == 34 ? 10 : 30,
            total: 1000000,
          );
          async.flushMicrotasks();
        }

        expect(success().users, hasLength(1000));
        expect(success().hasMore, isFalse);
        expect(success().isCapped, isTrue);
        container.dispose();
      });
    });
  });

  group('reconnecting', () {
    void goOfflineThenOnline(FakeAsync async) {
      connectivity.online = false;
      async.flushMicrotasks();
      connectivity.online = true;
      async.flushMicrotasks();
    }

    test('retries a search that failed because the device was offline', () {
      fakeAsync((async) {
        setUpContainer();
        async.flushMicrotasks();
        notifier().submit('octo');
        repository.fail('octo', const NetworkFailure());
        async.flushMicrotasks();

        goOfflineThenOnline(async);

        expect(repository.calls, hasLength(2));
        expect(state(), isA<SearchLoading>());
        container.dispose();
      });
    });

    test('retries a failed page load after reconnecting', () {
      fakeAsync((async) {
        setUpContainer();
        async.flushMicrotasks();
        notifier().submit('octo');
        repository.succeed('octo', count: 30, total: 100);
        async.flushMicrotasks();
        notifier().loadMore();
        repository.fail('octo', const TimeoutFailure(), page: 2);
        async.flushMicrotasks();

        goOfflineThenOnline(async);

        expect(repository.calls.where((c) => c.page == 2), hasLength(2));
        container.dispose();
      });
    });

    test('does not retry errors unrelated to connectivity', () {
      fakeAsync((async) {
        setUpContainer();
        async.flushMicrotasks();
        notifier().submit('octo');
        repository.fail('octo', const InvalidQueryFailure());
        async.flushMicrotasks();

        goOfflineThenOnline(async);

        expect(repository.calls, hasLength(1));
        expect(state(), isA<SearchError>());
        container.dispose();
      });
    });
  });
}
