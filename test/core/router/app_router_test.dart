import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/app.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../helpers/fake_search_repository.dart';
import '../../helpers/fake_user_detail_repository.dart';

void main() {
  late FakeSearchRepository searchRepository;
  late FakeUserDetailRepository detailRepository;

  Future<void> pumpApp(WidgetTester tester) async {
    searchRepository = FakeSearchRepository();
    detailRepository = FakeUserDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepository),
          userDetailRepositoryProvider.overrideWithValue(detailRepository),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  testWidgets('starts on the search page', (tester) async {
    await pumpApp(tester);

    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('tapping a result opens its detail page and back returns to '
      'the same results', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);
    searchRepository.succeed('octo', count: 2, total: 2);
    await tester.pump();

    await tester.tap(find.text('octo1'));
    await pumpTransition(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(detailRepository.calls.single.username, 'octo1');
    expect(
      containerOf(tester).read(routerProvider).state.uri.path,
      '/search/user/octo1',
    );

    detailRepository.succeed('octo1');
    await tester.pump();
    expect(find.text('The octo1'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('octo0'), findsOneWidget);
    expect(searchRepository.calls, hasLength(1));
  });

  testWidgets('a user URL opens the detail page directly', (tester) async {
    await pumpApp(tester);

    containerOf(tester).read(routerProvider).go(AppRoutes.searchUser('hubot'));
    await pumpTransition(tester);

    expect(find.byType(UserDetailPage), findsOneWidget);
    expect(detailRepository.calls.single.username, 'hubot');
  });

  testWidgets('unknown routes show a not found page', (tester) async {
    await pumpApp(tester);

    containerOf(tester).read(routerProvider).go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);

    await tester.tap(find.text('Go to search'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
  });
}
