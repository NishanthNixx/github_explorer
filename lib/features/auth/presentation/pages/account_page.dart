import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/account.dart';
import '../providers/account_provider.dart';
import '../providers/auth_notifier.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);

    final Widget body;
    if (account.hasValue) {
      body = _AccountDetails(account: account.requireValue);
    } else if (account.hasError && !account.isLoading) {
      final error = account.error;
      body = FailureView(
        failure: error is AppFailure ? error : UnknownFailure(error),
        onRetry: () => ref.invalidate(accountProvider),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: body,
    );
  }
}

class _AccountDetails extends ConsumerWidget {
  const _AccountDetails({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 36,
              child: Text(
                account.displayName[0].toUpperCase(),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              account.displayName,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              '@${account.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Verified by protected call'),
              subtitle: Text('GET /auth/me with Bearer token'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login_rounded),
              title: const Text('Session started'),
              subtitle: Text(formatTime(account.sessionIssuedAt)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Session expires'),
              subtitle: Text(formatTime(account.sessionExpiresAt)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  static String formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
