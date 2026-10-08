import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/cancellation_token.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_remote_data_source.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';

import '../../../helpers/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late UserDetailRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) async => jsonResponse({}, 200));
    repository = UserDetailRepositoryImpl(
      UserDetailRemoteDataSource(buildTestDio(adapter)),
    );
  });

  test('requests /users/{username}', () async {
    adapter.responder = (_) async =>
        jsonResponse({'id': 1, 'login': 'octocat'}, 200);

    await repository.getUser('octocat');

    expect(adapter.requests.single.path, '/users/octocat');
  });

  test('parses a full profile', () async {
    adapter.responder = (_) async => jsonResponse({
      'id': 583231,
      'login': 'octocat',
      'avatar_url': 'https://avatars.githubusercontent.com/u/583231',
      'html_url': 'https://github.com/octocat',
      'name': 'The Octocat',
      'company': '@github',
      'blog': 'https://github.blog',
      'location': 'San Francisco',
      'email': null,
      'bio': null,
      'twitter_username': null,
      'public_repos': 8,
      'followers': 17000,
      'following': 9,
      'created_at': '2011-01-25T18:44:36Z',
    }, 200);

    final user = await repository.getUser('octocat');

    expect(user.id, 583231);
    expect(user.login, 'octocat');
    expect(user.name, 'The Octocat');
    expect(user.displayName, 'The Octocat');
    expect(user.company, '@github');
    expect(user.blog, 'https://github.blog');
    expect(user.location, 'San Francisco');
    expect(user.email, isNull);
    expect(user.bio, isNull);
    expect(user.publicRepos, 8);
    expect(user.followers, 17000);
    expect(user.following, 9);
    expect(user.createdAt, DateTime.utc(2011, 1, 25, 18, 44, 36));
  });

  test('treats blank strings as missing and defaults counts to zero', () async {
    adapter.responder = (_) async => jsonResponse({
      'id': 2,
      'login': 'ghost',
      'name': '   ',
      'blog': '',
    }, 200);

    final user = await repository.getUser('ghost');

    expect(user.name, isNull);
    expect(user.displayName, 'ghost');
    expect(user.blog, isNull);
    expect(user.followers, 0);
    expect(user.htmlUrl, 'https://github.com/ghost');
  });

  test('404 throws NotFoundFailure', () async {
    adapter.responder = (_) async =>
        jsonResponse({'message': 'Not Found'}, 404);

    await expectLater(
      repository.getUser('nobody-here'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('rate limit throws RateLimitFailure', () async {
    adapter.responder = (_) async => jsonResponse(
      {'message': 'API rate limit exceeded'},
      403,
      headers: {
        'x-ratelimit-remaining': ['0'],
      },
    );

    await expectLater(
      repository.getUser('octocat'),
      throwsA(isA<RateLimitFailure>()),
    );
  });

  test('malformed body throws UnknownFailure', () async {
    adapter.responder = (_) async => jsonResponse({'login': 42}, 200);

    await expectLater(
      repository.getUser('octocat'),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('already cancelled token never hits the network', () async {
    final token = CancellationToken()..cancel();

    await expectLater(
      repository.getUser('octocat', cancellationToken: token),
      throwsA(isA<RequestCancelledFailure>()),
    );
    expect(adapter.requests, isEmpty);
  });
}
