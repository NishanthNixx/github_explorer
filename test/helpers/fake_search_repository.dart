import 'dart:async';

import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/cancellation_token.dart';
import 'package:github_explorer_starter/features/search/domain/github_user.dart';
import 'package:github_explorer_starter/features/search/domain/search_repository.dart';
import 'package:github_explorer_starter/features/search/domain/search_result_page.dart';

typedef SearchCall = ({
  String query,
  int page,
  int perPage,
  CancellationToken? token,
});

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.honorCancellation = true});

  final bool honorCancellation;
  final List<SearchCall> calls = [];
  final Map<String, Completer<SearchResultPage>> _pending = {};

  @override
  Future<SearchResultPage> searchUsers({
    required String query,
    required int page,
    int perPage = 30,
    CancellationToken? cancellationToken,
  }) {
    calls.add((
      query: query,
      page: page,
      perPage: perPage,
      token: cancellationToken,
    ));
    final completer = Completer<SearchResultPage>();
    _pending[_key(query, page)] = completer;
    if (honorCancellation) {
      cancellationToken?.whenCancelled.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(const RequestCancelledFailure());
        }
      });
    }
    return completer.future;
  }

  void succeed(
    String query, {
    int page = 1,
    int count = 2,
    int total = 2,
    int perPage = 30,
    int? firstId,
  }) {
    final start = firstId ?? (page - 1) * perPage;
    _pending[_key(query, page)]!.complete(
      SearchResultPage(
        users: [for (var id = start; id < start + count; id++) user(query, id)],
        totalCount: total,
        page: page,
        perPage: perPage,
      ),
    );
  }

  void fail(String query, AppFailure failure, {int page = 1}) {
    _pending[_key(query, page)]!.completeError(failure);
  }

  static GithubUser user(String query, int id) => GithubUser(
    id: id,
    login: '$query$id',
    avatarUrl: '',
    htmlUrl: 'https://github.com/$query$id',
  );

  String _key(String query, int page) => '$query#$page';
}
