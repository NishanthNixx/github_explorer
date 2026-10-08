import 'package:flutter/material.dart';

import '../network/app_failure.dart';
import 'status_view.dart';

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = describe(failure, DateTime.now());
    final canRetry = failure is! InvalidQueryFailure;

    return StatusView(
      icon: icon,
      title: title,
      message: message,
      onAction: canRetry ? onRetry : null,
    );
  }

  static (IconData, String, String) describe(AppFailure failure, DateTime now) {
    return switch (failure) {
      NetworkFailure() => (
        Icons.wifi_off_rounded,
        "You're offline",
        'Check your internet connection and try again.',
      ),
      TimeoutFailure() => (
        Icons.hourglass_bottom_rounded,
        'Request timed out',
        'GitHub is taking too long to respond. Try again in a moment.',
      ),
      RateLimitFailure(:final resetAt) => (
        Icons.speed_rounded,
        'Rate limit reached',
        _rateLimitMessage(resetAt, now),
      ),
      UnauthorizedFailure() => (
        Icons.lock_outline_rounded,
        'Not authorized',
        'Your credentials are invalid or have expired.',
      ),
      NotFoundFailure() => (
        Icons.person_off_outlined,
        'Not found',
        "We couldn't find what you were looking for.",
      ),
      InvalidQueryFailure(:final message) => (
        Icons.search_off_rounded,
        'Invalid search',
        message ?? 'GitHub could not process this search. Try changing it.',
      ),
      ServerFailure(:final statusCode) => (
        Icons.cloud_off_rounded,
        'GitHub had a problem',
        statusCode == null
            ? 'Please try again later.'
            : 'The server responded with status $statusCode. Please try again later.',
      ),
      RequestCancelledFailure() => (
        Icons.cancel_outlined,
        'Request cancelled',
        'The request was cancelled.',
      ),
      UnknownFailure() => (
        Icons.error_outline_rounded,
        'Something unexpected happened',
        'Please try again.',
      ),
    };
  }

  static String _rateLimitMessage(DateTime? resetAt, DateTime now) {
    if (resetAt == null) {
      return 'Too many requests to GitHub. Wait a minute and try again.';
    }

    final remaining = resetAt.difference(now);
    if (remaining <= Duration.zero) {
      return 'You can try again now.';
    }
    if (remaining.inMinutes < 1) {
      return 'Too many requests to GitHub. Try again in ${remaining.inSeconds + 1}s.';
    }
    return 'Too many requests to GitHub. Try again in ${remaining.inMinutes + 1} min.';
  }
}
