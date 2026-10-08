import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_impl.dart';
import '../../data/session_events.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_session.dart';
import 'auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  Timer? _expiryTimer;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final subscription = ref
        .watch(sessionEventsProvider)
        .unauthorized
        .listen((_) => _expireSession());
    ref.onDispose(() {
      subscription.cancel();
      _expiryTimer?.cancel();
    });

    _restore();
    return const AuthUnknown();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final session = await _repository.login(
      username: username.trim(),
      password: password,
    );
    if (!ref.mounted) return;
    _setAuthenticated(session);
  }

  Future<void> logout() async {
    _expiryTimer?.cancel();
    await _repository.logout();
    if (!ref.mounted) return;
    state = const Unauthenticated();
  }

  Future<void> _restore() async {
    final restored = await _repository.restoreSession();
    if (!ref.mounted) return;

    switch (restored) {
      case ActiveSession(:final session):
        _setAuthenticated(session);
      case ExpiredSession():
        state = const Unauthenticated(sessionExpired: true);
      case NoSession():
        state = const Unauthenticated();
    }
  }

  void _setAuthenticated(AuthSession session) {
    _expiryTimer?.cancel();
    final remaining = session.expiresAt.difference(clock.now());
    _expiryTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      _expireSession,
    );
    state = Authenticated(session);
  }

  Future<void> _expireSession() async {
    if (state is! Authenticated) return;
    _expiryTimer?.cancel();
    state = const Unauthenticated(sessionExpired: true);
    await _repository.logout();
  }
}
