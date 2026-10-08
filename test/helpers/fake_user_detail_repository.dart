import 'dart:async';

import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/cancellation_token.dart';
import 'package:github_explorer_starter/features/user_detail/domain/user_detail.dart';
import 'package:github_explorer_starter/features/user_detail/domain/user_detail_repository.dart';

class FakeUserDetailRepository implements UserDetailRepository {
  final List<({String username, CancellationToken? token})> calls = [];
  final Map<String, Completer<UserDetail>> _pending = {};

  @override
  Future<UserDetail> getUser(
    String username, {
    CancellationToken? cancellationToken,
  }) {
    calls.add((username: username, token: cancellationToken));
    final completer = Completer<UserDetail>();
    _pending[username] = completer;
    cancellationToken?.whenCancelled.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(const RequestCancelledFailure());
      }
    });
    return completer.future;
  }

  void succeed(String username, [UserDetail? user]) {
    _pending[username]!.complete(user ?? sampleUser(username));
  }

  void fail(String username, AppFailure failure) {
    _pending[username]!.completeError(failure);
  }

  static UserDetail sampleUser(String login) => UserDetail(
    id: 1,
    login: login,
    avatarUrl: '',
    htmlUrl: 'https://github.com/$login',
    publicRepos: 8,
    followers: 12345,
    following: 9,
    name: 'The $login',
    bio: 'Building things',
    company: '@github',
    location: 'San Francisco',
    createdAt: DateTime.utc(2011, 1, 25),
  );
}
