import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/features/user_detail/domain/profile_share_content.dart';
import 'package:github_explorer_starter/features/user_detail/domain/user_detail.dart';

void main() {
  UserDetail user({String? name}) => UserDetail(
    id: 1,
    login: 'octocat',
    avatarUrl: '',
    htmlUrl: 'https://github.com/octocat',
    publicRepos: 0,
    followers: 0,
    following: 0,
    name: name,
  );

  test('includes the display name, login and profile URL', () {
    final content = ProfileShareContent.forUser(user(name: 'The Octocat'));

    expect(
      content.text,
      'Check out The Octocat (@octocat) on GitHub: https://github.com/octocat',
    );
    expect(content.subject, 'The Octocat on GitHub');
  });

  test('falls back to the login when there is no name', () {
    final content = ProfileShareContent.forUser(user());

    expect(
      content.text,
      'Check out @octocat on GitHub: https://github.com/octocat',
    );
    expect(content.subject, 'octocat on GitHub');
  });
}
