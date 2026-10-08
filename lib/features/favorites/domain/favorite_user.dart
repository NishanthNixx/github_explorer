class FavoriteUser {
  const FavoriteUser({
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.addedAt,
    this.name,
  });

  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final String? name;
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteUser &&
          other.id == id &&
          other.login == login &&
          other.avatarUrl == avatarUrl &&
          other.htmlUrl == htmlUrl &&
          other.name == name &&
          other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(id, login, avatarUrl, htmlUrl, name, addedAt);

  @override
  String toString() => 'FavoriteUser($login)';
}
