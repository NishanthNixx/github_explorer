class GithubUser {
  const GithubUser({
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GithubUser &&
          other.id == id &&
          other.login == login &&
          other.avatarUrl == avatarUrl &&
          other.htmlUrl == htmlUrl;

  @override
  int get hashCode => Object.hash(id, login, avatarUrl, htmlUrl);

  @override
  String toString() => 'GithubUser($login)';
}
