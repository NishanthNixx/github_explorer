import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

import 'jwt_session_parser.dart';
import 'session_events.dart';
import 'token_store.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenStore, required this.sessionEvents});

  static const String requiresAuthKey = 'requiresAuth';

  static Options protected([Options? options]) {
    final base = options ?? Options();
    return base.copyWith(extra: {...?base.extra, requiresAuthKey: true});
  }

  final TokenStore tokenStore;
  final SessionEvents sessionEvents;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_requiresAuth(options)) {
      handler.next(options);
      return;
    }

    final token = await tokenStore.read();
    final session = token == null ? null : parseSessionToken(token);
    if (token == null || session == null || session.isExpiredAt(clock.now())) {
      sessionEvents.notifyUnauthorized();
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: options, statusCode: 401),
          message: 'Session missing or expired',
        ),
      );
      return;
    }

    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_requiresAuth(err.requestOptions) && err.response?.statusCode == 401) {
      sessionEvents.notifyUnauthorized();
    }
    handler.next(err);
  }

  bool _requiresAuth(RequestOptions options) =>
      options.extra[requiresAuthKey] == true;
}
