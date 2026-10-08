import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/platform/share_service.dart';
import 'package:github_explorer_starter/features/user_detail/data/user_detail_repository_impl.dart';
import 'package:github_explorer_starter/features/user_detail/presentation/pages/user_detail_page.dart';

import '../../../../helpers/fake_favorites_repository.dart';
import '../../../../helpers/fake_user_detail_repository.dart';

class FakeShareService implements ShareService {
  ShareOutcome outcome = ShareOutcome.shared;
  final List<({String text, String? subject, Rect? origin})> shares = [];

  @override
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
    Rect? origin,
  }) async {
    shares.add((text: text, subject: subject, origin: origin));
    return outcome;
  }
}

void main() {
  late FakeShareService shareService;
  late FakeUserDetailRepository repository;

  Future<void> pumpLoadedProfile(WidgetTester tester) async {
    shareService = FakeShareService();
    repository = FakeUserDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesOverride(),
          shareServiceProvider.overrideWithValue(shareService),
          userDetailRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: UserDetailPage(username: 'octocat')),
      ),
    );
    repository.succeed('octocat');
    await tester.pump();
  }

  testWidgets('share is hidden until the profile has loaded', (tester) async {
    shareService = FakeShareService();
    repository = FakeUserDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesOverride(),
          shareServiceProvider.overrideWithValue(shareService),
          userDetailRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: UserDetailPage(username: 'octocat')),
      ),
    );

    expect(find.byTooltip('Share profile'), findsNothing);
  });

  testWidgets('shares the profile URL anchored to the share button', (
    tester,
  ) async {
    await pumpLoadedProfile(tester);

    await tester.tap(find.byTooltip('Share profile'));
    await tester.pump();

    final share = shareService.shares.single;
    expect(
      share.text,
      'Check out The octocat (@octocat) on GitHub: https://github.com/octocat',
    );
    expect(share.subject, 'The octocat on GitHub');

    final buttonRect = tester.getRect(find.byTooltip('Share profile'));
    expect(share.origin, isNotNull);
    expect(share.origin!.isEmpty, isFalse);
    expect(share.origin!.overlaps(buttonRect), isTrue);
  });

  testWidgets('a failed share shows a snackbar', (tester) async {
    await pumpLoadedProfile(tester);
    shareService.outcome = ShareOutcome.failed;

    await tester.tap(find.byTooltip('Share profile'));
    await tester.pump();

    expect(
      find.text("Couldn't open the share sheet. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('dismissing the share sheet shows nothing', (tester) async {
    await pumpLoadedProfile(tester);
    shareService.outcome = ShareOutcome.dismissed;

    await tester.tap(find.byTooltip('Share profile'));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
