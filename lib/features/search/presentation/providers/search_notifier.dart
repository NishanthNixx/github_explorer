import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/network/cancellation_token.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/search_repository_impl.dart';
import '../../domain/github_user.dart';
import 'search_state.dart';

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  static const Duration debounceDuration = Duration(milliseconds: 400);
  static const int perPage = 30;

  Timer? _debounce;
  CancellationToken? _inFlight;
  String _query = '';

  String get query => _query;

  @override
  SearchState build() {
    ref.onDispose(_cancelPending);
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) _onReconnected();
    });
    return const SearchIdle();
  }

  void onQueryChanged(String input) {
    final query = input.trim();
    if (query == _query) return;

    _query = query;
    _cancelPending();

    if (query.isEmpty) {
      state = const SearchIdle();
      return;
    }

    _debounce = Timer(debounceDuration, () => _search(query));
  }

  void submit(String input) {
    final query = input.trim();
    _query = query;
    _cancelPending();

    if (query.isEmpty) {
      state = const SearchIdle();
      return;
    }

    _search(query);
  }

  void retry() {
    if (_query.isEmpty) return;
    _cancelPending();
    _search(_query);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SearchSuccess ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreFailure != null ||
        current.query != _query ||
        (_debounce?.isActive ?? false)) {
      return;
    }

    final token = _startRequest();
    state = current.copyWith(isLoadingMore: true);

    try {
      final result = await ref
          .read(searchRepositoryProvider)
          .searchUsers(
            query: current.query,
            page: current.page + 1,
            perPage: perPage,
            cancellationToken: token,
          );
      final latest = _latestSuccessFor(current.query, token);
      if (latest == null) return;

      state = latest.copyWith(
        users: _appendUnique(latest.users, result.users),
        totalCount: result.totalCount,
        page: result.page,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } on RequestCancelledFailure {
      return;
    } on AppFailure catch (failure) {
      final latest = _latestSuccessFor(current.query, token);
      if (latest == null) return;
      state = latest.copyWith(isLoadingMore: false, loadMoreFailure: failure);
    } finally {
      _finishRequest(token);
    }
  }

  void retryLoadMore() {
    final current = state;
    if (current is! SearchSuccess || current.loadMoreFailure == null) return;
    state = current.copyWith(clearLoadMoreFailure: true);
    loadMore();
  }

  void _onReconnected() {
    final current = state;
    if (current is SearchError && current.failure.isConnectivityIssue) {
      retry();
    } else if (current is SearchSuccess &&
        (current.loadMoreFailure?.isConnectivityIssue ?? false)) {
      retryLoadMore();
    }
  }

  Future<void> _search(String query) async {
    final token = _startRequest();
    state = SearchLoading(query);

    try {
      final result = await ref
          .read(searchRepositoryProvider)
          .searchUsers(
            query: query,
            page: 1,
            perPage: perPage,
            cancellationToken: token,
          );
      if (token.isCancelled || !ref.mounted) return;

      state = result.isEmpty
          ? SearchEmpty(query)
          : SearchSuccess(
              query: query,
              users: result.users,
              totalCount: result.totalCount,
              page: result.page,
              hasMore: result.hasMore,
            );
    } on RequestCancelledFailure {
      return;
    } on AppFailure catch (failure) {
      if (token.isCancelled || !ref.mounted) return;
      state = SearchError(query, failure);
    } finally {
      _finishRequest(token);
    }
  }

  CancellationToken _startRequest() {
    _inFlight?.cancel();
    final token = CancellationToken();
    _inFlight = token;
    return token;
  }

  void _finishRequest(CancellationToken token) {
    if (identical(_inFlight, token)) _inFlight = null;
  }

  SearchSuccess? _latestSuccessFor(String query, CancellationToken token) {
    if (token.isCancelled || !ref.mounted) return null;
    final latest = state;
    if (latest is! SearchSuccess || latest.query != query) return null;
    return latest;
  }

  List<GithubUser> _appendUnique(
    List<GithubUser> existing,
    List<GithubUser> incoming,
  ) {
    final seen = {for (final user in existing) user.id};
    return [
      ...existing,
      for (final user in incoming)
        if (seen.add(user.id)) user,
    ];
  }

  void _cancelPending() {
    _debounce?.cancel();
    _debounce = null;
    _inFlight?.cancel();
    _inFlight = null;
  }
}
