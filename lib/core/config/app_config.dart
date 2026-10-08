/// Compile-time configuration.
///
/// Values come from `--dart-define` / `--dart-define-from-file=env.json`
/// (see `env.example.json`). Nothing secret is ever hardcoded here.
abstract final class AppConfig {
  static const String githubApiBaseUrl = 'https://api.github.com';

  /// Optional GitHub personal access token. Raises the rate limit when set;
  /// the app works without it.
  static const String githubToken = String.fromEnvironment('GITHUB_TOKEN');

  static bool get hasGithubToken => githubToken.isNotEmpty;
}
