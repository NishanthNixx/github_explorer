import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:github_explorer_starter/core/network/connectivity_service.dart';

class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this.initiallyOnline = true});

  final bool initiallyOnline;
  final StreamController<bool> _changes = StreamController.broadcast();
  late bool _online = initiallyOnline;

  bool get online => _online;

  set online(bool value) {
    _online = value;
    _changes.add(value);
  }

  @override
  Stream<bool> watchOnline() async* {
    yield _online;
    yield* _changes.stream;
  }
}

Override connectivityOverride(FakeConnectivityService service) =>
    connectivityServiceProvider.overrideWithValue(service);
