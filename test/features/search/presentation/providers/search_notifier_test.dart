import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/cancellation_token.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/domain/github_user.dart';
import 'package:github_explorer_starter/features/search/domain/search_repository.dart';
import 'package:github_explorer_starter/features/search/domain/search_result_page.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_state.dart';

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.honorCancellation = true});

  final bool honorCancellation;
  final List<({String query, int page, CancellationToken? token})> calls = [];
  final Map<String, Completer<SearchResultPage>> _pending = {};

  @override
  Future<SearchResultPage> searchUsers({
    required String query,
    required int page,
    int perPage = 30,
    CancellationToken? cancellationToken,
  }) {
    calls.add((query: query, page: page, token: cancellationToken));
    final completer = Completer<SearchResultPage>();
    _pending[query] = completer;
    if (honorCancellation) {
      cancellationToken?.whenCancelled.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(const RequestCancelledFailure());
        }
      });
    }
    return completer.future;
  }

  void succeed(String query, {int count = 2, int total = 2}) {
    _pending[query]!.complete(
      SearchResultPage(
        users: [
          for (var i = 0; i < count; i++)
            GithubUser(
              id: i,
              login: '$query$i',
              avatarUrl: '',
              htmlUrl: 'https://github.com/$query$i',
            ),
        ],
        totalCount: total,
        page: 1,
        perPage: 30,
      ),
    );
  }

  void fail(String query, AppFailure failure) {
    _pending[query]!.completeError(failure);
  }
}

void main() {
  const debounce = SearchNotifier.debounceDuration;

  late FakeSearchRepository repository;
  late ProviderContainer container;

  void setUpContainer(FakeAsync async, {bool honorCancellation = true}) {
    repository = FakeSearchRepository(honorCancellation: honorCancellation);
    container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
    );
    container.read(searchProvider);
  }

  SearchNotifier notifier() => container.read(searchProvider.notifier);
  SearchState state() => container.read(searchProvider);

  test('starts idle', () {
    fakeAsync((async) {
      setUpContainer(async);

      expect(state(), isA<SearchIdle>());
      container.dispose();
    });
  });

  test('debounces typing and only searches the final query', () {
    fakeAsync((async) {
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async, honorCancellation: false);

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
      setUpContainer(async, honorCancellation: false);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

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
      setUpContainer(async);

      notifier().onQueryChanged('octo');
      container.dispose();
      async.elapse(debounce * 2);

      expect(repository.calls, isEmpty);
    });
  });
}
