import '../../domain/auth_session.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  final bool sessionExpired;
}

final class Authenticated extends AuthState {
  const Authenticated(this.session);

  final AuthSession session;
}
