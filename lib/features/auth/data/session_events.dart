import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

class SessionEvents {
  final StreamController<void> _unauthorized = StreamController.broadcast();

  Stream<void> get unauthorized => _unauthorized.stream;

  void notifyUnauthorized() {
    if (!_unauthorized.isClosed) _unauthorized.add(null);
  }

  void dispose() => _unauthorized.close();
}
