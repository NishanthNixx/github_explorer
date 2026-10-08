import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/cancellation_token.dart';
import 'package:github_explorer_starter/features/search/data/search_remote_data_source.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/domain/github_user.dart';

import '../../../helpers/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late SearchRepositoryImpl repository;

  void respondWith(FakeResponder responder) => adapter.responder = responder;

  setUp(() {
    adapter = FakeHttpClientAdapter(
      (_) async => jsonResponse({'total_count': 0, 'items': []}, 200),
    );
    repository = SearchRepositoryImpl(
      SearchRemoteDataSource(buildTestDio(adapter)),
    );
  });

  test('sends query, page and per_page to /search/users', () async {
    await repository.searchUsers(query: 'flutter dev', page: 3, perPage: 50);

    final request = adapter.requests.single;
    expect(request.path, '/search/users');
    expect(request.queryParameters, {
      'q': 'flutter dev',
      'page': 3,
      'per_page': 50,
    });
  });

  test('parses users and total count', () async {
    respondWith(
      (_) async => jsonResponse({
        'total_count': 2,
        'items': [
          {
            'id': 1,
            'login': 'octocat',
            'avatar_url': 'https://avatars.githubusercontent.com/u/1',
            'html_url': 'https://github.com/octocat',
          },
          {'id': 2, 'login': 'hubot'},
        ],
      }, 200),
    );

    final result = await repository.searchUsers(query: 'o', page: 1);

    expect(result.totalCount, 2);
    expect(result.page, 1);
    expect(result.users, const [
      GithubUser(
        id: 1,
        login: 'octocat',
        avatarUrl: 'https://avatars.githubusercontent.com/u/1',
        htmlUrl: 'https://github.com/octocat',
      ),
      GithubUser(
        id: 2,
        login: 'hubot',
        avatarUrl: '',
        htmlUrl: 'https://github.com/hubot',
      ),
    ]);
  });

  test('empty items returns an empty page', () async {
    final result = await repository.searchUsers(query: 'zzzz', page: 1);

    expect(result.isEmpty, isTrue);
    expect(result.hasMore, isFalse);
  });

  test('rate limited response throws RateLimitFailure', () async {
    respondWith(
      (_) async => jsonResponse(
        {'message': 'API rate limit exceeded'},
        403,
        headers: {
          'x-ratelimit-remaining': ['0'],
          'x-ratelimit-reset': ['1791460800'],
        },
      ),
    );

    await expectLater(
      repository.searchUsers(query: 'o', page: 1),
      throwsA(isA<RateLimitFailure>()),
    );
  });

  test('422 throws InvalidQueryFailure', () async {
    respondWith(
      (_) async => jsonResponse({'message': 'Validation Failed'}, 422),
    );

    await expectLater(
      repository.searchUsers(query: 'o', page: 1),
      throwsA(isA<InvalidQueryFailure>()),
    );
  });

  test('connection error throws NetworkFailure', () async {
    respondWith(
      (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );

    await expectLater(
      repository.searchUsers(query: 'o', page: 1),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('malformed body throws UnknownFailure', () async {
    respondWith((_) async => jsonResponse({'unexpected': true}, 200));

    await expectLater(
      repository.searchUsers(query: 'o', page: 1),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test(
    'cancelling an in-flight request throws RequestCancelledFailure',
    () async {
      respondWith((_) => Completer<ResponseBody>().future);
      final token = CancellationToken();

      final future = repository.searchUsers(
        query: 'o',
        page: 1,
        cancellationToken: token,
      );
      token.cancel();

      await expectLater(future, throwsA(isA<RequestCancelledFailure>()));
    },
  );

  test('already cancelled token never hits the network', () async {
    final token = CancellationToken()..cancel();

    await expectLater(
      repository.searchUsers(query: 'o', page: 1, cancellationToken: token),
      throwsA(isA<RequestCancelledFailure>()),
    );
    expect(adapter.requests, isEmpty);
  });
}
