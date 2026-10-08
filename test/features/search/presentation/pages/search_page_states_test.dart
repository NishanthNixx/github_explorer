import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';

import '../../../../helpers/fake_search_repository.dart';

void main() {
  late FakeSearchRepository repository;

  Future<void> pumpSearchPage(WidgetTester tester) async {
    repository = FakeSearchRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SearchPage()),
      ),
    );
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(SearchNotifier.debounceDuration);
  }

  testWidgets('idle shows a prompt', (tester) async {
    await pumpSearchPage(tester);

    expect(find.text('Search GitHub users'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('loading shows a spinner', (tester) async {
    await pumpSearchPage(tester);
    await search(tester, 'octo');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty results show the query', (tester) async {
    await pumpSearchPage(tester);
    await search(tester, 'zzzz');
    repository.succeed('zzzz', count: 0, total: 0);
    await tester.pump();

    expect(find.text('No users found'), findsOneWidget);
    expect(find.text('No GitHub users match "zzzz".'), findsOneWidget);
  });

  testWidgets('network error shows offline state and retry searches again', (
    tester,
  ) async {
    await pumpSearchPage(tester);
    await search(tester, 'octo');
    repository.fail('octo', const NetworkFailure());
    await tester.pump();

    expect(find.text("You're offline"), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(repository.calls, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('rate limit shows its own state, distinct from offline', (
    tester,
  ) async {
    await pumpSearchPage(tester);
    await search(tester, 'octo');
    repository.fail('octo', const RateLimitFailure());
    await tester.pump();

    expect(find.text('Rate limit reached'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
  });

  testWidgets('success lists users', (tester) async {
    await pumpSearchPage(tester);
    await search(tester, 'octo');
    repository.succeed('octo', count: 2, total: 2);
    await tester.pump();

    expect(find.text('octo0'), findsOneWidget);
    expect(find.text('octo1'), findsOneWidget);
  });

  testWidgets('clear button resets to idle', (tester) async {
    await pumpSearchPage(tester);
    await search(tester, 'octo');
    repository.succeed('octo', count: 2, total: 2);
    await tester.pump();

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    expect(find.text('octo0'), findsNothing);
    expect(
      find.text('Start typing a username to see matching profiles.'),
      findsOneWidget,
    );
  });
}
