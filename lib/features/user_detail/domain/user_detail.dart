class UserDetail {
  const UserDetail({
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.name,
    this.bio,
    this.company,
    this.location,
    this.blog,
    this.email,
    this.twitterUsername,
    this.createdAt,
  });

  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int publicRepos;
  final int followers;
  final int following;
  final String? name;
  final String? bio;
  final String? company;
  final String? location;
  final String? blog;
  final String? email;
  final String? twitterUsername;
  final DateTime? createdAt;

  String get displayName => name ?? login;
}
