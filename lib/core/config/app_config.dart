abstract final class AppConfig {
  static const String githubApiBaseUrl = 'https://api.github.com';

  static const String githubToken = String.fromEnvironment('GITHUB_TOKEN');

  static bool get hasGithubToken => githubToken.isNotEmpty;
}
