import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/router/app_router.dart';
import 'package:github_explorer_starter/features/auth/domain/auth_session.dart';
import 'package:github_explorer_starter/features/auth/presentation/providers/auth_state.dart';

void main() {
  final signedIn = Authenticated(
    AuthSession(
      token: 't',
      username: 'demo',
      issuedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2027),
    ),
  );
  const signedOut = Unauthenticated();
  const restoring = AuthUnknown();

  String? redirect(AuthState auth, String location) =>
      authRedirect(auth, Uri.parse(location));

  group('while restoring the session', () {
    test('any page goes to splash and remembers the target', () {
      expect(
        redirect(restoring, '/search/user/octocat'),
        '/splash?from=%2Fsearch%2Fuser%2Foctocat',
      );
    });

    test('search needs no from parameter', () {
      expect(redirect(restoring, '/search'), '/splash');
    });

    test('splash stays put', () {
      expect(redirect(restoring, '/splash?from=%2Faccount'), isNull);
    });
  });

  group('signed out', () {
    test('protected pages go to login with the target', () {
      expect(redirect(signedOut, '/account'), '/login?from=%2Faccount');
    });

    test('splash forwards its target to login', () {
      expect(
        redirect(signedOut, '/splash?from=%2Fsearch%2Fuser%2Fhubot'),
        '/login?from=%2Fsearch%2Fuser%2Fhubot',
      );
    });

    test('login stays put', () {
      expect(redirect(signedOut, '/login?from=%2Faccount'), isNull);
    });
  });

  group('signed in', () {
    test('normal pages are allowed', () {
      expect(redirect(signedIn, '/search/user/octocat'), isNull);
    });

    test('login sends the user to the remembered target', () {
      expect(
        redirect(signedIn, '/login?from=%2Fsearch%2Fuser%2Foctocat'),
        '/search/user/octocat',
      );
    });

    test('splash without a target goes to search', () {
      expect(redirect(signedIn, '/splash'), '/search');
    });

    test('external or looping targets fall back to search', () {
      expect(redirect(signedIn, '/login?from=https://evil.example'), '/search');
      expect(redirect(signedIn, '/login?from=//evil.example'), '/search');
      expect(redirect(signedIn, '/login?from=%2Flogin'), '/search');
    });
  });
}
