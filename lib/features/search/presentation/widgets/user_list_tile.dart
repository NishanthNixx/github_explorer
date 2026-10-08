import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/github_user.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  final GithubUser user;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(login: user.login, avatarUrl: user.avatarUrl),
      title: Text(user.login),
      trailing:
          trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      selected: selected,
      onTap: onTap,
    );
  }
}
