class AuthSession {
  const AuthSession({
    required this.token,
    required this.username,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String token;
  final String username;
  final DateTime issuedAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}
