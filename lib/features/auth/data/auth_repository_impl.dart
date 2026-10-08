import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/account.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_interceptor.dart';
import 'auth_remote_data_source.dart';
import 'jwt_session_parser.dart';
import 'mock_auth_server.dart';
import 'session_events.dart';
import 'token_store.dart';

final mockAuthServerProvider = Provider<MockAuthServer>((ref) {
  return MockAuthServer(tokenLifetime: AppConfig.authTokenLifetime);
});

final authDioProvider = Provider<Dio>((ref) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: MockAuthServer.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        )
        ..httpClientAdapter = ref.watch(mockAuthServerProvider)
        ..interceptors.add(
          AuthInterceptor(
            tokenStore: ref.watch(tokenStoreProvider),
            sessionEvents: ref.watch(sessionEventsProvider),
          ),
        );
  ref.onDispose(dio.close);
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(authDioProvider)),
    ref.watch(tokenStoreProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStore);

  final AuthRemoteDataSource _remote;
  final TokenStore _tokenStore;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final String token;
    try {
      token = await _remote.login(username: username, password: password);
    } on DioException catch (e) {
      final failure = mapDioException(e);
      throw failure is UnauthorizedFailure
          ? const InvalidCredentialsFailure()
          : failure;
    } on FormatException catch (e) {
      throw UnknownFailure(e);
    }

    final session = parseSessionToken(token);
    if (session == null) {
      throw const UnknownFailure('Server returned an unreadable token');
    }

    await _tokenStore.write(token);
    return session;
  }

  @override
  Future<RestoredSession> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null) return const NoSession();

    final session = parseSessionToken(token);
    if (session == null) {
      await _tokenStore.delete();
      return const NoSession();
    }

    if (session.isExpiredAt(clock.now())) {
      await _tokenStore.delete();
      return const ExpiredSession();
    }

    return ActiveSession(session);
  }

  @override
  Future<void> logout() => _tokenStore.delete();

  @override
  Future<Account> fetchAccount() async {
    try {
      final data = await _remote.fetchMe();
      final username = data['username'];
      final issuedAt = data['iat'];
      final expiresAt = data['exp'];
      if (username is! String || issuedAt is! int || expiresAt is! int) {
        throw FormatException('Invalid account payload', data);
      }

      final name = data['name'];
      return Account(
        username: username,
        displayName: name is String ? name : username,
        sessionIssuedAt: _fromEpochSeconds(issuedAt),
        sessionExpiresAt: _fromEpochSeconds(expiresAt),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw UnknownFailure(e);
    }
  }

  static DateTime _fromEpochSeconds(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}
