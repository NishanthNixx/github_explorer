import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/features/search/data/search_repository_impl.dart';
import 'package:github_explorer_starter/features/search/presentation/pages/search_page.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_notifier.dart';

import '../../../../helpers/fake_favorites_repository.dart';
import '../../../../helpers/fake_search_repository.dart';

void main() {
  final resultsScrollable = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );

  testWidgets('typing searches once and scrolling to the end loads page 2', (
    tester,
  ) async {
    final repository = FakeSearchRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesOverride(),
          searchRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SearchPage()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'octo');
    await tester.pump(SearchNotifier.debounceDuration);

    expect(repository.calls.map((c) => (c.query, c.page)), [('octo', 1)]);

    repository.succeed('octo', count: 30, total: 100);
    await tester.pump();

    expect(find.text('octo0'), findsOneWidget);
    expect(repository.calls, hasLength(1));

    await tester.scrollUntilVisible(
      find.byType(CircularProgressIndicator),
      500,
      scrollable: resultsScrollable,
    );
    await tester.pump();

    expect(repository.calls.last.page, 2);

    repository.succeed('octo', page: 2, count: 30, total: 100);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('octo59'),
      500,
      scrollable: resultsScrollable,
    );
    expect(find.text('octo59'), findsOneWidget);
  });
}
