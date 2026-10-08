import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../../data/favorites_repository_impl.dart';
import '../../domain/favorite_user.dart';

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<FavoriteUser>>(
      FavoritesNotifier.new,
      retry: (_, _) => null,
    );

final isFavoriteProvider = Provider.family<bool, int>((ref, id) {
  return ref.watch(
    favoritesProvider.select(
      (favorites) => favorites.value?.any((user) => user.id == id) ?? false,
    ),
  );
});

class FavoritesNotifier extends AsyncNotifier<List<FavoriteUser>> {
  @override
  Future<List<FavoriteUser>> build() async {
    final repository = await ref.watch(favoritesRepositoryProvider.future);
    return repository.getAll();
  }

  Future<void> toggle({
    required int id,
    required String login,
    required String avatarUrl,
    required String htmlUrl,
    String? name,
  }) async {
    final current = await future;
    if (current.any((user) => user.id == id)) {
      await _remove(current.firstWhere((user) => user.id == id));
    } else {
      await _add(
        FavoriteUser(
          id: id,
          login: login,
          avatarUrl: avatarUrl,
          htmlUrl: htmlUrl,
          name: name,
          addedAt: clock.now().toUtc(),
        ),
      );
    }
  }

  Future<void> _add(FavoriteUser user) async {
    _update((users) => [user, ...users.where((u) => u.id != user.id)]);
    try {
      final repository = await ref.read(favoritesRepositoryProvider.future);
      await repository.save(user);
    } on AppFailure {
      _update((users) => users.where((u) => u.id != user.id).toList());
      rethrow;
    }
  }

  Future<void> _remove(FavoriteUser user) async {
    _update((users) => users.where((u) => u.id != user.id).toList());
    try {
      final repository = await ref.read(favoritesRepositoryProvider.future);
      await repository.remove(user.id);
    } on AppFailure {
      _update(
        (users) =>
            [...users.where((u) => u.id != user.id), user]
              ..sort((a, b) => b.addedAt.compareTo(a.addedAt)),
      );
      rethrow;
    }
  }

  void _update(List<FavoriteUser> Function(List<FavoriteUser>) change) {
    if (!ref.mounted) return;
    final users = state.value ?? const <FavoriteUser>[];
    state = AsyncData(List.unmodifiable(change(users)));
  }
}
