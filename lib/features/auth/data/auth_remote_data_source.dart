import 'package:dio/dio.dart';

import 'auth_interceptor.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    final data = response.data;
    if (data is! Map || data['access_token'] is! String) {
      throw FormatException('Unexpected login response body', data);
    }
    return data['access_token'] as String;
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await _dio.get<Object?>(
      '/auth/me',
      options: AuthInterceptor.protected(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException('Unexpected account response body', data);
    }
    return data;
  }
}
