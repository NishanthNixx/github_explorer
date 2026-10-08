import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';
import 'package:github_explorer_starter/features/auth/presentation/providers/account_provider.dart';
import 'package:github_explorer_starter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:github_explorer_starter/features/auth/presentation/providers/auth_state.dart';

import '../../../../helpers/auth_test_helpers.dart';

void main() {
  late MockAuthServer server;
  late InMemoryTokenStore tokenStore;
  late ProviderContainer container;

  void setUpContainer({String? storedToken}) {
    server = buildTestAuthServer();
    tokenStore = InMemoryTokenStore(storedToken);
    container = ProviderContainer(
      overrides: authOverrides(server: server, tokenStore: tokenStore),
    );
    container.listen(authProvider, (_, _) {});
  }

  void settle(FakeAsync async) =>
      async.elapse(const Duration(milliseconds: 10));

  String? storedToken(FakeAsync async) {
    String? token;
    tokenStore.read().then((value) => token = value);
    async.flushMicrotasks();
    return token;
  }

  AuthState state() => container.read(authProvider);
  AuthNotifier notifier() => container.read(authProvider.notifier);

  Future<void> signIn() => notifier().login(
    username: MockAuthServer.demoUsername,
    password: MockAuthServer.demoPassword,
  );

  test('starts unknown and resolves to unauthenticated without a token', () {
    fakeAsync((async) {
      setUpContainer();

      expect(state(), isA<AuthUnknown>());
      async.flushMicrotasks();

      expect(state(), isA<Unauthenticated>());
      expect((state() as Unauthenticated).sessionExpired, isFalse);
      container.dispose();
    });
  });

  test('restores a valid stored session', () {
    fakeAsync((async) {
      final token = buildTestAuthServer().issueToken(
        username: MockAuthServer.demoUsername,
      );
      setUpContainer(storedToken: token);
      settle(async);

      expect(state(), isA<Authenticated>());
      expect(
        (state() as Authenticated).session.username,
        MockAuthServer.demoUsername,
      );
      container.dispose();
    });
  });

  test('an expired stored session lands on unauthenticated with the '
      'expired flag', () {
    fakeAsync((async) {
      final token = buildTestAuthServer().issueToken(
        username: MockAuthServer.demoUsername,
        lifetime: const Duration(minutes: -1),
      );
      setUpContainer(storedToken: token);
      settle(async);

      expect((state() as Unauthenticated).sessionExpired, isTrue);
      expect(storedToken(async), isNull);
      container.dispose();
    });
  });

  test('login with valid credentials authenticates', () {
    fakeAsync((async) {
      setUpContainer();
      settle(async);

      signIn();
      settle(async);

      expect(state(), isA<Authenticated>());
      container.dispose();
    });
  });

  test('login with wrong credentials throws and stays unauthenticated', () {
    fakeAsync((async) {
      setUpContainer();
      settle(async);

      Object? error;
      notifier()
          .login(username: MockAuthServer.demoUsername, password: 'nope')
          .catchError((Object e) => error = e);
      settle(async);

      expect(error, isA<InvalidCredentialsFailure>());
      expect(state(), isA<Unauthenticated>());
      container.dispose();
    });
  });

  test('session expires automatically when the token lifetime passes', () {
    fakeAsync((async) {
      setUpContainer();
      settle(async);
      signIn();
      settle(async);

      async.elapse(testTokenLifetime - const Duration(seconds: 1));
      expect(state(), isA<Authenticated>());

      async.elapse(const Duration(seconds: 1));

      expect((state() as Unauthenticated).sessionExpired, isTrue);
      expect(storedToken(async), isNull);
      container.dispose();
    });
  });

  test('a 401 from a protected call signs the user out as expired', () {
    fakeAsync((async) {
      setUpContainer();
      settle(async);
      signIn();
      settle(async);

      final forged = JWT(
        {'iat': 0, 'exp': 9999999999},
        subject: MockAuthServer.demoUsername,
        issuer: MockAuthServer.baseUrl,
      ).sign(SecretKey('forged'), noIssueAt: true);
      tokenStore.write(forged);

      container.read(accountProvider.future).ignore();
      settle(async);

      expect((state() as Unauthenticated).sessionExpired, isTrue);
      container.dispose();
    });
  });

  test('logout clears the token and is not reported as expired', () {
    fakeAsync((async) {
      setUpContainer();
      settle(async);
      signIn();
      settle(async);

      notifier().logout();
      settle(async);

      expect((state() as Unauthenticated).sessionExpired, isFalse);
      expect(storedToken(async), isNull);

      async.elapse(testTokenLifetime * 2);
      expect((state() as Unauthenticated).sessionExpired, isFalse);
      container.dispose();
    });
  });
}
