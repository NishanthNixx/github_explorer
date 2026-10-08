import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/core/network/dio_error_mapper.dart';

void main() {
  final options = RequestOptions(path: '/search/users');
  final fixedNow = DateTime.utc(2026, 10, 8, 12);

  DioException ofType(DioExceptionType type, {Object? error}) =>
      DioException(requestOptions: options, type: type, error: error);

  DioException badResponse(
    int statusCode, {
    Map<String, List<String>> headers = const {},
    Object? data,
  }) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
        headers: Headers.fromMap(headers),
        data: data,
      ),
    );
  }

  AppFailure map(DioException e) => mapDioException(e, now: () => fixedNow);

  group('transport errors', () {
    test('cancel maps to RequestCancelledFailure', () {
      expect(
        map(ofType(DioExceptionType.cancel)),
        isA<RequestCancelledFailure>(),
      );
    });

    test('all timeout types map to TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(map(ofType(type)), isA<TimeoutFailure>(), reason: '$type');
      }
    });

    test('connection error maps to NetworkFailure', () {
      expect(
        map(ofType(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });

    test('unknown with SocketException maps to NetworkFailure', () {
      expect(
        map(
          ofType(
            DioExceptionType.unknown,
            error: const SocketException('no route'),
          ),
        ),
        isA<NetworkFailure>(),
      );
    });

    test('unknown with other error maps to UnknownFailure', () {
      expect(
        map(ofType(DioExceptionType.unknown, error: StateError('boom'))),
        isA<UnknownFailure>(),
      );
    });
  });

  group('rate limiting', () {
    test('403 with remaining 0 reads reset time from x-ratelimit-reset', () {
      final failure = map(
        badResponse(
          403,
          headers: {
            'x-ratelimit-remaining': ['0'],
            'x-ratelimit-reset': ['1791460800'],
          },
        ),
      );

      expect(failure, isA<RateLimitFailure>());
      expect(
        (failure as RateLimitFailure).resetAt,
        DateTime.fromMillisecondsSinceEpoch(1791460800 * 1000, isUtc: true),
      );
    });

    test('403 with retry-after uses it relative to now', () {
      final failure = map(
        badResponse(
          403,
          headers: {
            'retry-after': ['60'],
          },
        ),
      );

      expect(
        (failure as RateLimitFailure).resetAt,
        fixedNow.add(const Duration(seconds: 60)),
      );
    });

    test('403 with rate limit message and no headers', () {
      final failure = map(
        badResponse(
          403,
          data: {'message': 'API rate limit exceeded for 1.2.3.4.'},
        ),
      );

      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).resetAt, isNull);
    });

    test('429 maps to RateLimitFailure', () {
      expect(map(badResponse(429)), isA<RateLimitFailure>());
    });

    test('plain 403 is not treated as rate limiting', () {
      final failure = map(badResponse(403, data: {'message': 'Forbidden'}));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 403);
    });
  });

  group('http status codes', () {
    test('401 maps to UnauthorizedFailure', () {
      expect(map(badResponse(401)), isA<UnauthorizedFailure>());
    });

    test('404 maps to NotFoundFailure', () {
      expect(map(badResponse(404)), isA<NotFoundFailure>());
    });

    test('422 maps to InvalidQueryFailure with GitHub message', () {
      final failure = map(
        badResponse(422, data: {'message': 'Validation Failed'}),
      );

      expect(failure, isA<InvalidQueryFailure>());
      expect((failure as InvalidQueryFailure).message, 'Validation Failed');
    });

    test('500 maps to ServerFailure', () {
      final failure = map(badResponse(500));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });
  });
}
