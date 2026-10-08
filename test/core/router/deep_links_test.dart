import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/core/router/deep_links.dart';

void main() {
  String? redirect(String link) => deepLinkRedirect(Uri.parse(link));

  test('myapp://user/{username} opens the user in the search tab', () {
    expect(redirect('myapp://user/octocat'), '/search/user/octocat');
  });

  test('accepts the triple-slash form where user is in the path', () {
    expect(redirect('myapp:///user/octocat'), '/search/user/octocat');
  });

  test('accepts usernames with hyphens and ignores a trailing slash', () {
    expect(redirect('myapp://user/mona-lisa/'), '/search/user/mona-lisa');
  });

  test('myapp://favorites opens the favorites tab', () {
    expect(redirect('myapp://favorites'), '/favorites');
  });

  test('invalid or unknown links fall back to search', () {
    expect(redirect('myapp://user'), '/search');
    expect(redirect('myapp://user/-bad'), '/search');
    expect(redirect('myapp://user/a%20b'), '/search');
    expect(redirect('myapp://user/octocat/extra'), '/search');
    expect(redirect('myapp://settings'), '/search');
  });

  test('in-app locations are left alone', () {
    expect(redirect('/search/user/octocat'), isNull);
    expect(redirect('https://github.com/octocat'), isNull);
  });

  test('builds the canonical deep link for a user', () {
    expect(DeepLinks.user('octocat').toString(), 'myapp://user/octocat');
  });
}
