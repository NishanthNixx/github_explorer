import 'package:dio/dio.dart';

import '../../config/app_config.dart';

/// Attaches the optional GitHub personal access token to every request.
///
/// Without a token the API still works, just with a lower rate limit.
class GithubTokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.hasGithubToken) {
      options.headers['Authorization'] = 'Bearer ${AppConfig.githubToken}';
    }
    handler.next(options);
  }
}
