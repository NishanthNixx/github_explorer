class Account {
  const Account({
    required this.username,
    required this.displayName,
    required this.sessionIssuedAt,
    required this.sessionExpiresAt,
  });

  final String username;
  final String displayName;
  final DateTime sessionIssuedAt;
  final DateTime sessionExpiresAt;
}
