import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../domain/auth_session.dart';

AuthSession? parseSessionToken(String token) {
  try {
    final payload = JWT.decode(token).payload;
    if (payload is! Map) return null;

    final subject = payload['sub'];
    final issuedAt = payload['iat'];
    final expiresAt = payload['exp'];
    if (subject is! String || issuedAt is! int || expiresAt is! int) {
      return null;
    }

    return AuthSession(
      token: token,
      username: subject,
      issuedAt: _fromEpochSeconds(issuedAt),
      expiresAt: _fromEpochSeconds(expiresAt),
    );
  } on JWTException {
    return null;
  } on FormatException {
    return null;
  }
}

DateTime _fromEpochSeconds(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
