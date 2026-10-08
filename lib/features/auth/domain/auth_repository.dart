import 'account.dart';
import 'auth_session.dart';

sealed class RestoredSession {
  const RestoredSession();
}

final class ActiveSession extends RestoredSession {
  const ActiveSession(this.session);

  final AuthSession session;
}

final class ExpiredSession extends RestoredSession {
  const ExpiredSession();
}

final class NoSession extends RestoredSession {
  const NoSession();
}

abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<RestoredSession> restoreSession();

  Future<void> logout();

  Future<Account> fetchAccount();
}
