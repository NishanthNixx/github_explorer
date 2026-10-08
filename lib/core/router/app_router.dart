import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/account_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/user_detail/presentation/pages/user_detail_page.dart';
import 'app_shell.dart';
import 'route_not_found_page.dart';

abstract final class AppRoutes {
  static const String search = '/search';
  static const String login = '/login';
  static const String splash = '/splash';
  static const String account = '/account';
  static const String favorites = '/favorites';

  static String searchUser(String username) =>
      '$search/user/${Uri.encodeComponent(username)}';

  static String favoriteUser(String username) =>
      '$favorites/user/${Uri.encodeComponent(username)}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => authChanges.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.search,
    refreshListenable: authChanges,
    redirect: (_, state) => authRedirect(ref.read(authProvider), state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.search),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.account, builder: (_, _) => const AccountPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const SearchPage(),
                routes: [_userDetailRoute()],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (_, _) => const FavoritesPage(),
                routes: [_userDetailRoute()],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => RouteNotFoundPage(location: state.uri.path),
  );

  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});

GoRoute _userDetailRoute() => GoRoute(
  path: 'user/:username',
  builder: (_, state) =>
      UserDetailPage(username: state.pathParameters['username']!),
);

@visibleForTesting
String? authRedirect(AuthState auth, Uri uri) {
  final path = uri.path;
  final onSplash = path == AppRoutes.splash;
  final onLogin = path == AppRoutes.login;
  final from = uri.queryParameters['from'];

  switch (auth) {
    case AuthUnknown():
      if (onSplash) return null;
      return _withFrom(AppRoutes.splash, onLogin ? from : uri.toString());
    case Unauthenticated():
      if (onLogin) return null;
      return _withFrom(AppRoutes.login, onSplash ? from : uri.toString());
    case Authenticated():
      if (!onLogin && !onSplash) return null;
      return _safeTarget(from);
  }
}

String _withFrom(String path, String? from) {
  final target = _safeTarget(from);
  if (target == AppRoutes.search) return path;
  return Uri(path: path, queryParameters: {'from': target}).toString();
}

String _safeTarget(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return AppRoutes.search;
  }
  final path = Uri.tryParse(from)?.path;
  if (path == null ||
      path == '/' ||
      path == AppRoutes.login ||
      path == AppRoutes.splash) {
    return AppRoutes.search;
  }
  return from;
}
