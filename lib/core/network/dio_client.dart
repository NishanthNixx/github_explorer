import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'interceptors/github_token_interceptor.dart';

/// Builds the single [Dio] instance used for all GitHub API calls.
///
/// Prefer reading it through `dioProvider` rather than calling this directly,
/// so tests can override it.
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.githubApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );

  dio.interceptors.add(GithubTokenInterceptor());

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        // Headers stay off so the token never ends up in logs.
        requestHeader: false,
        responseHeader: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
}
