import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'interceptors/github_token_interceptor.dart';

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
        requestHeader: false,
        responseHeader: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
}
