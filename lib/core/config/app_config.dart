abstract final class AppConfig {
  static const String githubApiBaseUrl = 'https://api.github.com';

  static const String githubToken = String.fromEnvironment('GITHUB_TOKEN');

  static bool get hasGithubToken => githubToken.isNotEmpty;

  static const Duration authTokenLifetime = Duration(
    seconds: int.fromEnvironment('AUTH_TOKEN_TTL_SECONDS', defaultValue: 300),
  );
}
