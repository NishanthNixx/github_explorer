import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/search/presentation/providers/search_state.dart';
import 'package:github_explorer_starter/features/search/presentation/widgets/search_results_list.dart';

import '../../../../helpers/fake_search_repository.dart';

void main() {
  SearchSuccess successState({
    int count = 30,
    int total = 100,
    bool hasMore = true,
    AppFailure? loadMoreFailure,
  }) {
    return SearchSuccess(
      query: 'octo',
      users: [
        for (var i = 0; i < count; i++) FakeSearchRepository.user('octo', i),
      ],
      totalCount: total,
      page: 1,
      hasMore: hasMore,
      loadMoreFailure: loadMoreFailure,
    );
  }

  Future<void> pumpList(
    WidgetTester tester,
    SearchSuccess state, {
    VoidCallback? onLoadMore,
    VoidCallback? onRetryLoadMore,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            state: state,
            onLoadMore: onLoadMore ?? () {},
            onRetryLoadMore: onRetryLoadMore ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('does not load more until the end of the list is reached', (
    tester,
  ) async {
    var loadMoreCalls = 0;
    await pumpList(tester, successState(), onLoadMore: () => loadMoreCalls++);
    await tester.pump();

    expect(loadMoreCalls, 0);

    await tester.scrollUntilVisible(
      find.byType(CircularProgressIndicator),
      500,
    );
    await tester.pump();

    expect(loadMoreCalls, 1);
  });

  testWidgets('loads more right away when the first page does not fill the '
      'screen', (tester) async {
    var loadMoreCalls = 0;
    await pumpList(
      tester,
      successState(count: 3),
      onLoadMore: () => loadMoreCalls++,
    );
    await tester.pump();

    expect(loadMoreCalls, 1);
  });

  testWidgets('shows an inline retry row when loading more fails', (
    tester,
  ) async {
    var retryCalls = 0;
    await pumpList(
      tester,
      successState(count: 3, loadMoreFailure: const NetworkFailure()),
      onRetryLoadMore: () => retryCalls++,
    );

    expect(find.text("Couldn't load more: You're offline"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Retry'));
    expect(retryCalls, 1);
  });

  testWidgets('shows a note when results are capped at 1000', (tester) async {
    await pumpList(
      tester,
      successState(count: 3, total: 50000, hasMore: false),
    );

    expect(
      find.textContaining('Showing the first 1000 results'),
      findsOneWidget,
    );
  });

  testWidgets('shows no footer once all results are loaded', (tester) async {
    var loadMoreCalls = 0;
    await pumpList(
      tester,
      successState(count: 3, total: 3, hasMore: false),
      onLoadMore: () => loadMoreCalls++,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(loadMoreCalls, 0);
  });
}
