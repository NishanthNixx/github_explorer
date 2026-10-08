import 'user_detail.dart';

class ProfileShareContent {
  const ProfileShareContent({required this.text, required this.subject});

  factory ProfileShareContent.forUser(UserDetail user) {
    final name = user.name;
    final who = name == null ? '@${user.login}' : '$name (@${user.login})';
    return ProfileShareContent(
      text: 'Check out $who on GitHub: ${user.htmlUrl}',
      subject: '${user.displayName} on GitHub',
    );
  }

  final String text;
  final String subject;
}
