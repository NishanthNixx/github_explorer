import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => PluginConnectivityService(Connectivity()),
);

final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).watchOnline(),
);

abstract interface class ConnectivityService {
  Stream<bool> watchOnline();
}

class PluginConnectivityService implements ConnectivityService {
  const PluginConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  static bool isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Stream<bool> watchOnline() => _watch().distinct();

  Stream<bool> _watch() async* {
    final List<ConnectivityResult> initial;
    try {
      initial = await _connectivity.checkConnectivity();
    } on MissingPluginException {
      yield true;
      return;
    } on PlatformException {
      yield true;
      return;
    }

    yield isOnline(initial);
    yield* _connectivity.onConnectivityChanged.map(isOnline);
  }
}
