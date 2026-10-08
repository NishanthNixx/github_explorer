import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/config/app_config.dart';
import 'package:github_explorer_starter/core/network/interceptors/github_token_interceptor.dart';
import 'package:github_explorer_starter/core/providers/core_providers.dart';

void main() {
  test('dioProvider is configured for the GitHub API', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, AppConfig.githubApiBaseUrl);
    expect(dio.options.headers['Accept'], 'application/vnd.github+json');
    expect(dio.interceptors.whereType<GithubTokenInterceptor>(), hasLength(1));
  });
}
