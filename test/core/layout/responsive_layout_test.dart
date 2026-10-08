import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/layout/window_size.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/features/favorites/presentation/pages/favorites_page.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  const phone = Size(390, 844);
  const smallTablet = Size(700, 1000);
  const tablet = Size(1280, 800);

  group('WindowSize', () {
    test('uses Material breakpoints', () {
      expect(WindowSize.fromWidth(599), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(839), WindowSize.medium);
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
    });
  });

  testWidgets('phone uses a bottom bar and full screen detail', (tester) async {
    final app = await TestApp.pump(tester, screenSize: phone);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Select a user'), findsNothing);

    await app.searchFor('octo');
    await tester.tap(find.text('octo1'));
    await app.settle();

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(find.byType(SearchPage), findsNothing);
  });

  testWidgets('small tablet uses a navigation rail with a single pane', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, screenSize: smallTablet);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await app.searchFor('octo');
    await tester.tap(find.text('octo1'));
    await app.settle();

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(find.byType(SearchPage), findsNothing);
  });

  testWidgets('tablet shows list and detail side by side', (tester) async {
    final app = await TestApp.pump(tester, screenSize: tablet);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('Select a user'), findsOneWidget);

    await app.searchFor('octo');
    await tester.tap(find.text('octo1'));
    await app.settle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(find.text('Select a user'), findsNothing);
    expect(app.router.state.uri.path, '/search/user/octo1');

    final selectedTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('octo1'), matching: find.byType(ListTile)),
    );
    expect(selectedTile.selected, isTrue);

    final searchLeft = tester.getTopLeft(find.byType(SearchPage)).dx;
    final detailLeft = tester.getTopLeft(find.byType(UserDetailPage)).dx;
    expect(detailLeft, greaterThan(searchLeft));
  });

  testWidgets('tablet keeps the list while switching between users', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, screenSize: tablet);
    await app.searchFor('octo');

    await tester.tap(find.text('octo0'));
    await app.settle();
    await tester.tap(find.text('octo2'));
    await app.settle();

    expect(app.detail.calls.map((c) => c.username), ['octo0', 'octo2']);
    expect(app.search.calls, hasLength(1));
    expect(find.widgetWithText(TextField, 'octo'), findsOneWidget);
  });

  testWidgets('tablet favorites tab uses the same master-detail layout', (
    tester,
  ) async {
    final app = await TestApp.pump(
      tester,
      screenSize: tablet,
      favorites: [favoriteUser(1, login: 'hubot')],
    );

    await tester.tap(find.text('Favorites').first);
    await app.settle();

    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text('Select a favorite'), findsOneWidget);

    await tester.tap(find.text('hubot'));
    await app.settle();

    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.byType(UserDetailPage), findsOneWidget);
  });

  testWidgets('a user URL on tablet opens with the list beside it', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, screenSize: tablet);

    app.router.go(AppRoutes.searchUser('hubot'));
    await app.settle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.byType(UserDetailPage), findsOneWidget);
  });

  testWidgets('resizing from tablet to phone keeps the query and the open '
      'profile', (tester) async {
    final app = await TestApp.pump(tester, screenSize: tablet);
    await app.searchFor('octo');
    await tester.tap(find.text('octo1'));
    await app.settle();

    TestApp.setScreenSize(tester, phone);
    await app.settle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(find.byType(SearchPage), findsNothing);

    await tester.pageBack();
    await app.settle();

    expect(find.widgetWithText(TextField, 'octo'), findsOneWidget);
    expect(find.text('octo1'), findsOneWidget);
    expect(app.search.calls, hasLength(1));
  });
}
