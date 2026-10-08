import '../../domain/user_detail.dart';

class UserDetailDto {
  const UserDetailDto({
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

  factory UserDetailDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final login = json['login'];
    if (id is! int || login is! String || login.isEmpty) {
      throw FormatException('Invalid GitHub user detail payload', json);
    }

    return UserDetailDto(
      id: id,
      login: login,
      avatarUrl: _string(json['avatar_url']) ?? '',
      htmlUrl: _string(json['html_url']) ?? 'https://github.com/$login',
      publicRepos: _int(json['public_repos']),
      followers: _int(json['followers']),
      following: _int(json['following']),
      name: _string(json['name']),
      bio: _string(json['bio']),
      company: _string(json['company']),
      location: _string(json['location']),
      blog: _string(json['blog']),
      email: _string(json['email']),
      twitterUsername: _string(json['twitter_username']),
      createdAt: DateTime.tryParse(_string(json['created_at']) ?? ''),
    );
  }

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

  UserDetail toEntity() => UserDetail(
    id: id,
    login: login,
    avatarUrl: avatarUrl,
    htmlUrl: htmlUrl,
    publicRepos: publicRepos,
    followers: followers,
    following: following,
    name: name,
    bio: bio,
    company: company,
    location: location,
    blog: blog,
    email: email,
    twitterUsername: twitterUsername,
    createdAt: createdAt,
  );

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _int(Object? value) => value is int ? value : 0;
}
