import '../../domain/github_user.dart';

class GithubUserDto {
  const GithubUserDto({
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  factory GithubUserDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final login = json['login'];
    if (id is! int || login is! String || login.isEmpty) {
      throw FormatException('Invalid GitHub user payload', json);
    }

    final avatarUrl = json['avatar_url'];
    final htmlUrl = json['html_url'];
    return GithubUserDto(
      id: id,
      login: login,
      avatarUrl: avatarUrl is String ? avatarUrl : '',
      htmlUrl: htmlUrl is String ? htmlUrl : 'https://github.com/$login',
    );
  }

  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;

  GithubUser toEntity() =>
      GithubUser(id: id, login: login, avatarUrl: avatarUrl, htmlUrl: htmlUrl);
}
