import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/core/widgets/offline_banner.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  const bannerText = "You're offline. Saved favorites are still available.";

  testWidgets('no banner while online', (tester) async {
    await TestApp.pump(tester);

    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('banner appears when the connection drops and hides when it '
      'returns', (tester) async {
    final app = await TestApp.pump(tester);

    app.connectivity.online = false;
    await app.settle();
    expect(find.text(bannerText), findsOneWidget);

    app.connectivity.online = true;
    await app.settle();
    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('starting offline shows the banner right away', (tester) async {
    await TestApp.pump(tester, online: false);

    expect(find.text(bannerText), findsOneWidget);
  });

  testWidgets('toggling the banner keeps the current screen and its state', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    await app.searchFor('octo');

    app.connectivity.online = false;
    await app.settle();
    app.connectivity.online = true;
    await app.settle();

    expect(find.widgetWithText(TextField, 'octo'), findsOneWidget);
    expect(find.text('octo0'), findsOneWidget);
    expect(app.search.calls, hasLength(1));
  });

  testWidgets('favorites stay readable while offline', (tester) async {
    final app = await TestApp.pump(
      tester,
      online: false,
      favorites: [favoriteUser(1, login: 'hubot')],
    );

    app.router.go(AppRoutes.favorites);
    await app.settle();

    expect(find.text(bannerText), findsOneWidget);
    expect(find.text('hubot'), findsOneWidget);
  });

  testWidgets('a profile that failed offline reloads once back online', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    app.router.go(AppRoutes.searchUser('octocat'));
    await app.settle();

    app.connectivity.online = false;
    app.detail.fail('octocat', const NetworkFailure());
    await app.settle();
    expect(find.text("You're offline"), findsOneWidget);

    app.connectivity.online = true;
    await app.settle();

    expect(app.detail.calls, hasLength(2));
    app.detail.succeed('octocat');
    await tester.pump();
    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(find.text('The octocat'), findsOneWidget);
  });
}
