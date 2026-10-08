import 'dart:io';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';

import 'app_failure.dart';

AppFailure mapDioException(DioException exception, {DateTime Function()? now}) {
  final currentTime = now ?? clock.now;
  return switch (exception.type) {
    DioExceptionType.cancel => const RequestCancelledFailure(),
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badCertificate => UnknownFailure(exception),
    DioExceptionType.badResponse => _mapResponse(
      exception.response,
      currentTime,
    ),
    DioExceptionType.unknown =>
      exception.error is SocketException
          ? const NetworkFailure()
          : UnknownFailure(exception.error ?? exception),
  };
}

AppFailure _mapResponse(Response<dynamic>? response, DateTime Function() now) {
  final statusCode = response?.statusCode;
  if (response == null || statusCode == null) {
    return const ServerFailure(null);
  }

  if (_isRateLimited(response)) {
    return RateLimitFailure(resetAt: _rateLimitResetAt(response, now));
  }

  return switch (statusCode) {
    401 => const UnauthorizedFailure(),
    404 => const NotFoundFailure(),
    422 => InvalidQueryFailure(_messageFrom(response.data)),
    _ => ServerFailure(statusCode),
  };
}

bool _isRateLimited(Response<dynamic> response) {
  final statusCode = response.statusCode;
  if (statusCode == 429) return true;
  if (statusCode != 403) return false;

  final headers = response.headers;
  if (headers.value('x-ratelimit-remaining') == '0') return true;
  if (headers.value('retry-after') != null) return true;

  final message = _messageFrom(response.data)?.toLowerCase() ?? '';
  return message.contains('rate limit');
}

DateTime? _rateLimitResetAt(
  Response<dynamic> response,
  DateTime Function() now,
) {
  final retryAfter = int.tryParse(response.headers.value('retry-after') ?? '');
  if (retryAfter != null) {
    return now().add(Duration(seconds: retryAfter));
  }

  final resetEpoch = int.tryParse(
    response.headers.value('x-ratelimit-reset') ?? '',
  );
  if (resetEpoch != null) {
    return DateTime.fromMillisecondsSinceEpoch(resetEpoch * 1000, isUtc: true);
  }

  return null;
}

String? _messageFrom(Object? data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}
