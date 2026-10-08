import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';

class MockAuthServer implements HttpClientAdapter {
  MockAuthServer({
    required this.tokenLifetime,
    this.latency = const Duration(milliseconds: 600),
  });

  static const String baseUrl = 'https://auth.mock.local';
  static const String demoUsername = 'demo';
  static const String demoPassword = 'flutter123';
  static const String _demoDisplayName = 'Demo User';
  static final SecretKey _signingKey = SecretKey('rheo-mock-auth-signing-key');

  final Duration tokenLifetime;
  final Duration latency;

  String issueToken({required String username, Duration? lifetime}) {
    final issuedAt = clock.now();
    final expiresAt = issuedAt.add(lifetime ?? tokenLifetime);
    return JWT(
      {
        'name': _demoDisplayName,
        'iat': _epochSeconds(issuedAt),
        'exp': _epochSeconds(expiresAt),
      },
      subject: username,
      issuer: baseUrl,
    ).sign(_signingKey, noIssueAt: true);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    return switch ((options.method, options.path)) {
      ('POST', '/auth/login') => _login(options.data),
      ('GET', '/auth/me') => _me(options.headers['Authorization']),
      _ => _json({'message': 'Not Found'}, 404),
    };
  }

  ResponseBody _login(Object? body) {
    if (body is! Map ||
        body['username'] != demoUsername ||
        body['password'] != demoPassword) {
      return _json({'message': 'Invalid username or password'}, 401);
    }

    return _json({
      'access_token': issueToken(username: demoUsername),
      'token_type': 'Bearer',
      'expires_in': tokenLifetime.inSeconds,
    }, 200);
  }

  ResponseBody _me(Object? authorization) {
    final jwt = _verify(authorization);
    if (jwt == null) {
      return _json({'message': 'Invalid or expired token'}, 401);
    }

    final payload = jwt.payload as Map;
    return _json({
      'username': jwt.subject,
      'name': payload['name'],
      'iat': payload['iat'],
      'exp': payload['exp'],
    }, 200);
  }

  JWT? _verify(Object? authorization) {
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }

    final jwt = JWT.tryVerify(
      authorization.substring('Bearer '.length),
      _signingKey,
      checkExpiresIn: false,
      issuer: baseUrl,
    );
    final payload = jwt?.payload;
    if (jwt == null || payload is! Map) return null;

    final expiresAt = payload['exp'];
    if (expiresAt is! int || _epochSeconds(clock.now()) >= expiresAt) {
      return null;
    }
    return jwt;
  }

  ResponseBody _json(Map<String, Object?> body, int statusCode) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static int _epochSeconds(DateTime time) =>
      time.millisecondsSinceEpoch ~/ 1000;

  @override
  void close({bool force = false}) {}
}
