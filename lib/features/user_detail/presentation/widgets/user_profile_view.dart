import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/user_detail.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key, required this.user});

  final UserDetail user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bio = user.bio;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Center(
              child: UserAvatar(
                login: user.login,
                avatarUrl: user.avatarUrl,
                radius: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (user.name != null)
              Text(
                '@${user.login}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            if (bio != null) ...[
              const SizedBox(height: 16),
              Text(
                bio,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            _StatsRow(user: user),
            const SizedBox(height: 16),
            const Divider(),
            ..._infoTiles(),
          ],
        ),
      ),
    );
  }

  List<Widget> _infoTiles() {
    final createdAt = user.createdAt;
    final twitter = user.twitterUsername;

    return [
      _InfoTile(icon: Icons.business_outlined, text: user.company),
      _InfoTile(icon: Icons.location_on_outlined, text: user.location),
      _InfoTile(icon: Icons.link_rounded, text: user.blog),
      _InfoTile(icon: Icons.mail_outline_rounded, text: user.email),
      _InfoTile(
        icon: Icons.alternate_email_rounded,
        text: twitter == null ? null : '@$twitter',
      ),
      _InfoTile(
        icon: Icons.calendar_today_outlined,
        text: createdAt == null ? null : 'Joined ${formatJoined(createdAt)}',
      ),
      _InfoTile(icon: Icons.open_in_new_rounded, text: user.htmlUrl),
    ].where((tile) => tile.text != null).toList();
  }

  static String formatJoined(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.year}';
  }

  static String formatCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) return _compact(value / 1000, 'k');
    return _compact(value / 1000000, 'M');
  }

  static String _compact(double value, String suffix) {
    final text = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '$text$suffix';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserDetail user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: 'Followers', value: user.followers),
        _Stat(label: 'Following', value: user.following),
        _Stat(label: 'Repositories', value: user.publicRepos),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              UserProfileView.formatCount(value),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(text ?? ''),
    );
  }
}
