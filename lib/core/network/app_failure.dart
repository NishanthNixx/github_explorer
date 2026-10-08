sealed class AppFailure implements Exception {
  const AppFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();

  @override
  String toString() => 'NetworkFailure()';
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();

  @override
  String toString() => 'TimeoutFailure()';
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({this.resetAt});

  final DateTime? resetAt;

  @override
  String toString() => 'RateLimitFailure(resetAt: $resetAt)';
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();

  @override
  String toString() => 'UnauthorizedFailure()';
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();

  @override
  String toString() => 'NotFoundFailure()';
}

final class InvalidQueryFailure extends AppFailure {
  const InvalidQueryFailure([this.message]);

  final String? message;

  @override
  String toString() => 'InvalidQueryFailure($message)';
}

final class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode);

  final int? statusCode;

  @override
  String toString() => 'ServerFailure($statusCode)';
}

final class RequestCancelledFailure extends AppFailure {
  const RequestCancelledFailure();

  @override
  String toString() => 'RequestCancelledFailure()';
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.cause]);

  final Object? cause;

  @override
  String toString() => 'UnknownFailure($cause)';
}
