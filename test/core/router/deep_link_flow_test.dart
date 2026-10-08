import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/presentation/pages/login_page.dart';
import 'package:github_explorer_starter/features/favorites/presentation/pages/favorites_page.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> openWhileRunning(WidgetTester tester, String link) async {
    final message = const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': link, 'state': null}),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      message,
      (_) {},
    );
  }

  void launchWith(WidgetTester tester, String link) {
    tester.platformDispatcher.defaultRouteNameTestValue = link;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
  }

  testWidgets('a link received while running opens the profile', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    expect(find.byType(SearchPage), findsOneWidget);

    await openWhileRunning(tester, 'myapp://user/octocat');
    await app.settle();

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(app.detail.calls.single.username, 'octocat');
    expect(app.router.state.uri.path, '/search/user/octocat');
  });

  testWidgets('a link that launches the app opens the profile directly', (
    tester,
  ) async {
    launchWith(tester, 'myapp://user/octocat');

    final app = await TestApp.pump(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(app.detail.calls.single.username, 'octocat');
  });

  testWidgets('a link opened while signed out goes through login first', (
    tester,
  ) async {
    launchWith(tester, 'myapp://user/octocat');

    final app = await TestApp.pump(tester, signedIn: false);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(app.detail.calls, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      MockAuthServer.demoUsername,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      MockAuthServer.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await app.settle();

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(app.detail.calls.single.username, 'octocat');
  });

  testWidgets('on a tablet the link opens next to the search list', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, screenSize: const Size(1280, 800));

    await openWhileRunning(tester, 'myapp://user/hubot');
    await app.settle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.byType(UserDetailPage), findsOneWidget);
  });

  testWidgets('myapp://favorites opens the favorites tab', (tester) async {
    final app = await TestApp.pump(tester);

    await openWhileRunning(tester, 'myapp://favorites');
    await app.settle();

    expect(find.byType(FavoritesPage), findsOneWidget);
  });

  testWidgets('an invalid link lands safely on search', (tester) async {
    final app = await TestApp.pump(tester);

    await openWhileRunning(tester, 'myapp://user/not a valid name');
    await app.settle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.byType(UserDetailPage), findsNothing);
    expect(app.detail.calls, isEmpty);
  });
}
