import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/network/cancellation_token.dart';
import '../../data/search_repository_impl.dart';
import 'search_state.dart';

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  static const Duration debounceDuration = Duration(milliseconds: 400);

  Timer? _debounce;
  CancellationToken? _inFlight;
  String _query = '';

  @override
  SearchState build() {
    ref.onDispose(_cancelPending);
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

  Future<void> _search(String query) async {
    final token = CancellationToken();
    _inFlight = token;
    state = SearchLoading(query);

    try {
      final result = await ref
          .read(searchRepositoryProvider)
          .searchUsers(query: query, page: 1, cancellationToken: token);
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
      if (identical(_inFlight, token)) _inFlight = null;
    }
  }

  void _cancelPending() {
    _debounce?.cancel();
    _debounce = null;
    _inFlight?.cancel();
    _inFlight = null;
  }
}
