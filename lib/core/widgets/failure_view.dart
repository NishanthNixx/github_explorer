import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../network/app_failure.dart';
import 'status_view.dart';

class FailureView extends StatefulWidget {
  const FailureView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

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
      InvalidCredentialsFailure() => (
        Icons.key_off_outlined,
        'Invalid credentials',
        'The username or password is incorrect.',
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

  static Duration rateLimitRemaining(AppFailure failure, DateTime now) {
    if (failure is! RateLimitFailure) return Duration.zero;
    final resetAt = failure.resetAt;
    if (resetAt == null) return Duration.zero;
    final remaining = resetAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static String _rateLimitMessage(DateTime? resetAt, DateTime now) {
    if (resetAt == null) {
      return 'Too many requests to GitHub. Wait a minute and try again.';
    }

    final remaining = resetAt.difference(now);
    if (remaining <= Duration.zero) {
      return 'You can try again now.';
    }
    return 'Too many requests to GitHub. You can retry in '
        '${_formatCountdown(remaining)}.';
  }

  static String _formatCountdown(Duration remaining) {
    final totalSeconds = (remaining.inMilliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  State<FailureView> createState() => _FailureViewState();
}

class _FailureViewState extends State<FailureView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(FailureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.failure, widget.failure)) _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (_remaining() == Duration.zero) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining() == Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  Duration _remaining() =>
      FailureView.rateLimitRemaining(widget.failure, clock.now());

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    final (icon, title, message) = FailureView.describe(failure, clock.now());
    final canRetry =
        failure is! InvalidQueryFailure && _remaining() == Duration.zero;

    return StatusView(
      icon: icon,
      title: title,
      message: message,
      onAction: canRetry ? widget.onRetry : null,
    );
  }
}
