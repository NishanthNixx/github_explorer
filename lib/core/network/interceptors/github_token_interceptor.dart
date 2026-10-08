import 'package:dio/dio.dart';

import '../../config/app_config.dart';

class GithubTokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.hasGithubToken) {
      options.headers['Authorization'] = 'Bearer ${AppConfig.githubToken}';
    }
    handler.next(options);
  }
}
