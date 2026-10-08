import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/app.dart';
import 'package:github_explorer_starter/features/auth/data/mock_auth_server.dart';
import 'package:github_explorer_starter/features/auth/data/token_store.dart';
import 'package:github_explorer_starter/features/favorites/domain/favorite_user.dart';
import 'package:github_explorer_starter/features/favorites/presentation/pages/favorites_page.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../../helpers/auth_test_helpers.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/fake_search_repository.dart';
import '../../../helpers/fake_user_detail_repository.dart';

void main() {
  late FakeSearchRepository searchRepository;
  late FakeUserDetailRepository detailRepository;
  late InMemoryFavoritesRepository favoritesRepository;

  Future<void> pumpFor(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<FavoriteUser> initialFavorites = const [],
  }) async {
    searchRepository = FakeSearchRepository();
    detailRepository = FakeUserDetailRepository();
    favoritesRepository = InMemoryFavoritesRepository(initialFavorites);
    final authServer = buildTestAuthServer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(
            server: authServer,
            tokenStore: InMemoryTokenStore(
              authServer.issueToken(username: MockAuthServer.demoUsername),
            ),
          ),
          searchRepositoryProvider.overrideWithValue(searchRepository),
          userDetailRepositoryProvider.overrideWithValue(detailRepository),
          favoritesOverride(favoritesRepository),
        ],
        child: const App(),
      ),
    );
    await pumpFor(tester);
  }

  Future<void> openFavoritesTab(WidgetTester tester) async {
    await tester.tap(find.text('Favorites').last);
    await pumpFor(tester);
  }

  testWidgets('favorites tab shows an empty state', (tester) async {
    await pumpApp(tester);

    await openFavoritesTab(tester);

    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('starring a search result adds it to the favorites tab', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);
    searchRepository.succeed('octo', count: 2, total: 2);
    await tester.pump();

    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();

    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(favoritesRepository.stored.single.login, 'octo0');

    await openFavoritesTab(tester);

    expect(find.text('octo0'), findsOneWidget);
    expect(find.text('No favorites yet'), findsNothing);
  });

  testWidgets('unstarring on the favorites tab removes the user', (
    tester,
  ) async {
    await pumpApp(tester, initialFavorites: [favoriteUser(1, login: 'hubot')]);
    await openFavoritesTab(tester);
    expect(find.text('hubot'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();

    expect(find.text('hubot'), findsNothing);
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(favoritesRepository.stored, isEmpty);
  });

  testWidgets('favoriting from the detail page stores the full name', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);
    searchRepository.succeed('octo', count: 1, total: 1);
    await tester.pump();

    await tester.tap(find.text('octo0'));
    await pumpFor(tester);
    detailRepository.succeed('octo0');
    await tester.pump();

    expect(find.byType(UserDetailPage), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();

    expect(favoritesRepository.stored.single.name, 'The octo0');
  });

  testWidgets('saved favorites are readable without any network call and '
      'open the detail page in the favorites tab', (tester) async {
    await pumpApp(
      tester,
      initialFavorites: [favoriteUser(1, login: 'hubot', name: 'Hubot')],
    );
    await openFavoritesTab(tester);

    expect(find.text('hubot'), findsOneWidget);
    expect(find.text('Hubot'), findsOneWidget);
    expect(searchRepository.calls, isEmpty);
    expect(detailRepository.calls, isEmpty);

    await tester.tap(find.text('hubot'));
    await pumpFor(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(detailRepository.calls.single.username, 'hubot');
  });

  testWidgets('a storage error while toggling shows a snackbar', (
    tester,
  ) async {
    await pumpApp(tester);
    favoritesRepository.failWrites = true;
    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);
    searchRepository.succeed('octo', count: 1, total: 1);
    await tester.pump();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();

    expect(
      find.text("Couldn't update favorites. Please try again."),
      findsOneWidget,
    );
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
  });

  testWidgets('switching tabs keeps the search results', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);
    searchRepository.succeed('octo', count: 2, total: 2);
    await tester.pump();

    await openFavoritesTab(tester);
    await tester.tap(find.text('Search').last);
    await pumpFor(tester);

    expect(find.text('octo1'), findsOneWidget);
    expect(searchRepository.calls, hasLength(1));
  });
}
