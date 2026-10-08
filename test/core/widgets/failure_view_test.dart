import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/widgets/failure_view.dart';

void main() {
  Future<void> pumpFailure(
    WidgetTester tester,
    AppFailure failure, {
    VoidCallback? onRetry,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FailureView(failure: failure, onRetry: onRetry ?? () {}),
        ),
      ),
    );
  }

  testWidgets('offline shows a specific message with retry', (tester) async {
    var retries = 0;
    await pumpFailure(tester, const NetworkFailure(), onRetry: () => retries++);

    expect(find.text("You're offline"), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('invalid query hides retry and shows the GitHub message', (
    tester,
  ) async {
    await pumpFailure(tester, const InvalidQueryFailure('Validation Failed'));

    expect(find.text('Invalid search'), findsOneWidget);
    expect(find.text('Validation Failed'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('rate limit counts down and enables retry when it resets', (
    tester,
  ) async {
    final resetAt = clock.now().add(const Duration(seconds: 65));
    await pumpFailure(tester, RateLimitFailure(resetAt: resetAt));

    expect(find.text('Rate limit reached'), findsOneWidget);
    expect(find.textContaining('retry in 1:05'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('retry in 1:04'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    expect(find.textContaining('retry in 0:04'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('You can try again now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('rate limit without a reset time allows retry', (tester) async {
    await pumpFailure(tester, const RateLimitFailure());

    expect(find.textContaining('Wait a minute'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('server failure includes the status code', (tester) async {
    await pumpFailure(tester, const ServerFailure(502));

    expect(find.text('GitHub had a problem'), findsOneWidget);
    expect(find.textContaining('status 502'), findsOneWidget);
  });
}
