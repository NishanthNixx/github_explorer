import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../../../helpers/fake_user_detail_repository.dart';

void main() {
  late FakeUserDetailRepository repository;

  Future<void> pumpPage(WidgetTester tester, String username) async {
    repository = FakeUserDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: UserDetailPage(username: username)),
      ),
    );
  }

  testWidgets('shows a spinner then the profile', (tester) async {
    await pumpPage(tester, 'octocat');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.calls.single.username, 'octocat');

    repository.succeed('octocat');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('The octocat'), findsOneWidget);
    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('Building things'), findsOneWidget);
    expect(find.text('12.3k'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('San Francisco'), findsOneWidget);
    expect(find.text('Joined Jan 2011'), findsOneWidget);
  });

  testWidgets('shows not found for an unknown user without auto retrying', (
    tester,
  ) async {
    await pumpPage(tester, 'nobody-here');

    repository.fail('nobody-here', const NotFoundFailure());
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('Not found'), findsOneWidget);
    expect(repository.calls, hasLength(1));
  });

  testWidgets('retry fetches the profile again after a network error', (
    tester,
  ) async {
    await pumpPage(tester, 'octocat');

    repository.fail('octocat', const NetworkFailure());
    await tester.pump();

    expect(find.text("You're offline"), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.calls, hasLength(2));

    repository.succeed('octocat');
    await tester.pump();

    expect(find.text('The octocat'), findsOneWidget);
  });

  testWidgets('leaving the page cancels the in-flight request', (tester) async {
    await pumpPage(tester, 'octocat');
    final token = repository.calls.single.token!;

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(token.isCancelled, isTrue);
  });
}
