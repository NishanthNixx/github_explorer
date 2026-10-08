import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:github_explorer_starter/app.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';
import 'package:github_explorer_starter/features/auth/presentation/pages/account_page.dart';
import 'package:github_explorer_starter/features/auth/presentation/pages/login_page.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../../helpers/auth_test_helpers.dart';
import '../../../helpers/fake_search_repository.dart';
import '../../../helpers/fake_user_detail_repository.dart';

void main() {
  late MockAuthServer server;
  late InMemoryTokenStore tokenStore;

  Future<void> pumpFor(WidgetTester tester, [int milliseconds = 600]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: milliseconds));
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    bool signedIn = false,
    Duration lifetime = testTokenLifetime,
  }) async {
    server = buildTestAuthServer(lifetime: lifetime);
    tokenStore = InMemoryTokenStore(
      signedIn
          ? server.issueToken(username: MockAuthServer.demoUsername)
          : null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(server: server, tokenStore: tokenStore),
          searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
          userDetailRepositoryProvider.overrideWithValue(
            FakeUserDetailRepository(),
          ),
        ],
        child: const App(),
      ),
    );
    await pumpFor(tester);
  }

  GoRouter router(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(Navigator).first),
  ).read(routerProvider);

  Future<void> signIn(WidgetTester tester, {String? password}) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      MockAuthServer.demoUsername,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password ?? MockAuthServer.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpFor(tester);
  }

  testWidgets('signed out users land on login', (tester) async {
    await pumpApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('Demo account'), findsOneWidget);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('wrong password shows an error and stays on login', (
    tester,
  ) async {
    await pumpApp(tester);

    await signIn(tester, password: 'wrong');

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('The username or password is incorrect.'), findsOneWidget);
    expect(await tokenStore.read(), isNull);
  });

  testWidgets('valid credentials open search and persist the token', (
    tester,
  ) async {
    await pumpApp(tester);

    await signIn(tester);

    expect(find.byType(SearchPage), findsOneWidget);
    expect(await tokenStore.read(), isNotNull);
  });

  testWidgets('a stored valid token skips login', (tester) async {
    await pumpApp(tester, signedIn: true);

    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('a user page requested while signed out opens after login', (
    tester,
  ) async {
    await pumpApp(tester);

    router(tester).go(AppRoutes.searchUser('octocat'));
    await pumpFor(tester);
    expect(find.byType(LoginPage), findsOneWidget);

    await signIn(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(router(tester).state.uri.path, '/search/user/octocat');
  });

  testWidgets('token expiry while browsing returns to login with a notice, '
      'and signing in again restores the page', (tester) async {
    await pumpApp(tester, signedIn: true, lifetime: const Duration(minutes: 1));
    router(tester).go(AppRoutes.searchUser('octocat'));
    await pumpFor(tester);
    expect(find.byType(UserDetailPage), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    await pumpFor(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(await tokenStore.read(), isNull);

    await signIn(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
  });

  testWidgets('account page shows data from the protected call and signs out', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(find.byTooltip('Account'));
    await pumpFor(tester);

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('Verified by protected call'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await pumpFor(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Your session expired. Please sign in again.'),
      findsNothing,
    );
    expect(await tokenStore.read(), isNull);
  });
}
