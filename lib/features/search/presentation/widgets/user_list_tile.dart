import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/github_user.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({super.key, required this.user, this.onTap});

  final GithubUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(login: user.login, avatarUrl: user.avatarUrl),
      title: Text(user.login),
      onTap: onTap,
    );
  }
}
