import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/widgets/failure_view.dart';
import '../providers/user_detail_provider.dart';
import '../widgets/user_profile_view.dart';

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(userDetailProvider(username));

    final Widget body;
    if (detail.hasValue) {
      body = UserProfileView(user: detail.requireValue);
    } else if (detail.hasError && !detail.isLoading) {
      final error = detail.error;
      body = FailureView(
        failure: error is AppFailure ? error : UnknownFailure(error),
        onRetry: () => ref.invalidate(userDetailProvider(username)),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: body,
    );
  }
}
