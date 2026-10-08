import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/favorite_user.dart';
import '../providers/favorites_notifier.dart';
import '../widgets/favorite_button.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    final Widget body;
    if (favorites.hasValue) {
      final users = favorites.requireValue;
      body = users.isEmpty
          ? const StatusView(
              icon: Icons.star_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the star on any user to save them here.',
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _FavoriteTile(key: ValueKey(user.id), user: user);
              },
            );
    } else if (favorites.hasError && !favorites.isLoading) {
      final error = favorites.error;
      body = FailureView(
        failure: error is AppFailure ? error : StorageFailure(error),
        onRetry: () => ref.invalidate(favoritesProvider),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: body,
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({super.key, required this.user});

  final FavoriteUser user;

  @override
  Widget build(BuildContext context) {
    final name = user.name;

    return ListTile(
      leading: UserAvatar(login: user.login, avatarUrl: user.avatarUrl),
      title: Text(user.login),
      subtitle: name == null ? null : Text(name),
      trailing: FavoriteButton(
        id: user.id,
        login: user.login,
        avatarUrl: user.avatarUrl,
        htmlUrl: user.htmlUrl,
        name: user.name,
      ),
      onTap: () => context.go(AppRoutes.favoriteUser(user.login)),
    );
  }
}
