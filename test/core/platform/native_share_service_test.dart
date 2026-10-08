import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/platform/share_service.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall call) respond;

  setUp(() {
    calls = [];
    respond = (_) async => 'com.apple.UIKit.activity.Message';
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return respond(call);
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  NativeShareService service() => NativeShareService(SharePlus.instance);

  test(
    'sends text, subject and the anchor rect to the native share sheet',
    () async {
      final outcome = await service().shareText(
        text: 'Check out @octocat on GitHub: https://github.com/octocat',
        subject: 'octocat on GitHub',
        origin: const Rect.fromLTWH(300, 40, 48, 48),
      );

      expect(outcome, ShareOutcome.shared);
      expect(calls.single.method, 'share');
      expect(calls.single.arguments, {
        'text': 'Check out @octocat on GitHub: https://github.com/octocat',
        'subject': 'octocat on GitHub',
        'originX': 300.0,
        'originY': 40.0,
        'originWidth': 48.0,
        'originHeight': 48.0,
      });
    },
  );

  test('a dismissed sheet is reported as dismissed', () async {
    respond = (_) async => '';

    expect(await service().shareText(text: 'hello'), ShareOutcome.dismissed);
  });

  test('platforms that cannot report the result return unknown', () async {
    respond = (_) async => null;

    expect(await service().shareText(text: 'hello'), ShareOutcome.unknown);
  });

  test('a platform error is reported as failed instead of throwing', () async {
    respond = (_) async => throw PlatformException(code: 'error');

    expect(await service().shareText(text: 'hello'), ShareOutcome.failed);
  });
}
