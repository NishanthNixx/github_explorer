import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  const eventChannel = EventChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  group('isOnline', () {
    test('any real connection counts as online', () {
      expect(
        PluginConnectivityService.isOnline([ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        PluginConnectivityService.isOnline([
          ConnectivityResult.none,
          ConnectivityResult.mobile,
        ]),
        isTrue,
      );
    });

    test('none or nothing counts as offline', () {
      expect(
        PluginConnectivityService.isOnline([ConnectivityResult.none]),
        isFalse,
      );
      expect(PluginConnectivityService.isOnline([]), isFalse);
    });
  });

  test('emits the current state, then changes without repeats', () async {
    messenger.setMockMethodCallHandler(
      methodChannel,
      (call) async => call.method == 'check' ? ['wifi'] : null,
    );
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          events.success(['wifi']);
          events.success(['none']);
          events.success(['none']);
          events.success(['mobile']);
          events.endOfStream();
        },
      ),
    );

    final states = await PluginConnectivityService(
      Connectivity(),
    ).watchOnline().toList();

    expect(states, [true, false, true]);
  });

  test('assumes online when the plugin is unavailable', () async {
    final states = await PluginConnectivityService(
      Connectivity(),
    ).watchOnline().toList();

    expect(states, [true]);
  });
}
