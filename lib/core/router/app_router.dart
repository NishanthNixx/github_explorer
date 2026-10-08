import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/search/presentation/pages/search_page.dart';
import '../../features/user_detail/presentation/pages/user_detail_page.dart';
import 'route_not_found_page.dart';

abstract final class AppRoutes {
  static const String search = '/search';

  static String searchUser(String username) =>
      '$search/user/${Uri.encodeComponent(username)}';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.search,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.search),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const SearchPage(),
        routes: [
          GoRoute(
            path: 'user/:username',
            builder: (_, state) =>
                UserDetailPage(username: state.pathParameters['username']!),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => RouteNotFoundPage(location: state.uri.path),
  );
  ref.onDispose(router.dispose);
  return router;
});
