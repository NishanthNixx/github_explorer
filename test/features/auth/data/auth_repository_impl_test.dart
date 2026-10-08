import 'package:clock/clock.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/auth/data/auth_repository_impl.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/session_events.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';
import 'package:github_explorer_starter/features/auth/domain/auth_repository.dart';

import '../../../helpers/auth_test_helpers.dart';

void main() {
  final startTime = DateTime.utc(2026, 1, 1, 12);

  late MockAuthServer server;
  late InMemoryTokenStore tokenStore;
  late ProviderContainer container;
  late AuthRepository repository;
  late List<void> unauthorizedEvents;

  setUp(() {
    server = buildTestAuthServer();
    tokenStore = InMemoryTokenStore();
    container = ProviderContainer(
      overrides: authOverrides(server: server, tokenStore: tokenStore),
    );
    addTearDown(container.dispose);
    repository = container.read(authRepositoryProvider);
    unauthorizedEvents = [];
    container
        .read(sessionEventsProvider)
        .unauthorized
        .listen(unauthorizedEvents.add);
  });

  Future<T> at<T>(DateTime time, Future<T> Function() body) =>
      withClock(Clock.fixed(time), body);

  Future<void> flushEvents() => Future<void>.delayed(Duration.zero);

  group('login', () {
    test('valid credentials return a session and store the JWT', () async {
      final session = await at(
        startTime,
        () => repository.login(
          username: MockAuthServer.demoUsername,
          password: MockAuthServer.demoPassword,
        ),
      );

      expect(session.username, MockAuthServer.demoUsername);
      expect(session.issuedAt, startTime);
      expect(session.expiresAt, startTime.add(testTokenLifetime));
      expect(await tokenStore.read(), session.token);
      expect(session.token.split('.'), hasLength(3));
    });

    test('wrong password throws InvalidCredentialsFailure and stores '
        'nothing', () async {
      await expectLater(
        repository.login(
          username: MockAuthServer.demoUsername,
          password: 'wrong',
        ),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await flushEvents();

      expect(await tokenStore.read(), isNull);
      expect(unauthorizedEvents, isEmpty);
    });
  });

  group('protected call', () {
    Future<void> signIn() => at(
      startTime,
      () => repository.login(
        username: MockAuthServer.demoUsername,
        password: MockAuthServer.demoPassword,
      ),
    );

    test('sends the Bearer token and returns the account', () async {
      await signIn();

      final account = await at(
        startTime.add(const Duration(minutes: 1)),
        repository.fetchAccount,
      );

      expect(account.username, MockAuthServer.demoUsername);
      expect(account.displayName, 'Demo User');
      expect(account.sessionExpiresAt, startTime.add(testTokenLifetime));
    });

    test('expired token is rejected before the request and signals '
        'unauthorized', () async {
      await signIn();

      await expectLater(
        at(
          startTime.add(testTokenLifetime + const Duration(seconds: 1)),
          repository.fetchAccount,
        ),
        throwsA(isA<UnauthorizedFailure>()),
      );
      await flushEvents();

      expect(unauthorizedEvents, hasLength(1));
    });

    test('token with a forged signature is rejected by the server', () async {
      final forged = JWT(
        {
          'name': 'Demo User',
          'iat': startTime.millisecondsSinceEpoch ~/ 1000,
          'exp':
              startTime.add(testTokenLifetime).millisecondsSinceEpoch ~/ 1000,
        },
        subject: MockAuthServer.demoUsername,
        issuer: MockAuthServer.baseUrl,
      ).sign(SecretKey('not-the-server-key'), noIssueAt: true);
      await tokenStore.write(forged);

      await expectLater(
        at(startTime, repository.fetchAccount),
        throwsA(isA<UnauthorizedFailure>()),
      );
      await flushEvents();

      expect(unauthorizedEvents, hasLength(1));
    });

    test('missing token is unauthorized', () async {
      await expectLater(
        repository.fetchAccount(),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });
  });

  group('restoreSession', () {
    test('no stored token', () async {
      expect(await repository.restoreSession(), isA<NoSession>());
    });

    test('valid stored token is restored', () async {
      final token = withClock(
        Clock.fixed(startTime),
        () => server.issueToken(username: MockAuthServer.demoUsername),
      );
      await tokenStore.write(token);

      final restored = await at(
        startTime.add(const Duration(minutes: 1)),
        repository.restoreSession,
      );

      expect(restored, isA<ActiveSession>());
      expect(
        (restored as ActiveSession).session.username,
        MockAuthServer.demoUsername,
      );
    });

    test('expired stored token is cleared and reported as expired', () async {
      final token = withClock(
        Clock.fixed(startTime),
        () => server.issueToken(username: MockAuthServer.demoUsername),
      );
      await tokenStore.write(token);

      final restored = await at(
        startTime.add(testTokenLifetime),
        repository.restoreSession,
      );

      expect(restored, isA<ExpiredSession>());
      expect(await tokenStore.read(), isNull);
    });

    test('garbage token is cleared', () async {
      await tokenStore.write('not-a-jwt');

      expect(await repository.restoreSession(), isA<NoSession>());
      expect(await tokenStore.read(), isNull);
    });
  });

  test('logout clears the stored token', () async {
    await tokenStore.write('anything');

    await repository.logout();

    expect(await tokenStore.read(), isNull);
  });
}
