import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/app.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';
import 'package:github_explorer_starter/features/favorites/domain/favorite_user.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:go_router/go_router.dart';

import 'auth_test_helpers.dart';
import 'fake_favorites_repository.dart';
import 'fake_search_repository.dart';
import 'fake_user_detail_repository.dart';

class TestApp {
  TestApp._(this.tester, this.search, this.detail, this.favorites);

  final WidgetTester tester;
  final FakeSearchRepository search;
  final FakeUserDetailRepository detail;
  final InMemoryFavoritesRepository favorites;

  static Future<TestApp> pump(
    WidgetTester tester, {
    Size? screenSize,
    List<FavoriteUser> favorites = const [],
    bool signedIn = true,
  }) async {
    if (screenSize != null) setScreenSize(tester, screenSize);

    final app = TestApp._(
      tester,
      FakeSearchRepository(),
      FakeUserDetailRepository(),
      InMemoryFavoritesRepository(favorites),
    );
    final authServer = buildTestAuthServer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(
            server: authServer,
            tokenStore: InMemoryTokenStore(
              signedIn
                  ? authServer.issueToken(username: MockAuthServer.demoUsername)
                  : null,
            ),
          ),
          searchRepositoryProvider.overrideWithValue(app.search),
          userDetailRepositoryProvider.overrideWithValue(app.detail),
          favoritesOverride(app.favorites),
        ],
        child: const App(),
      ),
    );
    await app.settle();
    return app;
  }

  static void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  GoRouter get router => ProviderScope.containerOf(
    tester.element(find.byType(Navigator).first),
  ).read(routerProvider);

  Future<void> settle() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> searchFor(String query, {int count = 3}) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(SearchNotifier.debounceDuration);
    search.succeed(query, count: count, total: count);
    await tester.pump();
  }
}
