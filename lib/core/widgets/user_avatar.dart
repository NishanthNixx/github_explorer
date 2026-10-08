import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.login,
    required this.avatarUrl,
    this.radius = 20,
  });

  final String login;
  final String avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl.isNotEmpty;

    return Semantics(
      label: '$login avatar',
      image: true,
      child: CircleAvatar(
        radius: radius,
        foregroundImage: hasImage ? NetworkImage(avatarUrl) : null,
        onForegroundImageError: hasImage ? (_, _) {} : null,
        child: Text(login.isEmpty ? '?' : login[0].toUpperCase()),
      ),
    );
  }
}
