import 'package:flutter_riverpod/misc.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/favorites/data/favorites_repository_impl.dart';
import 'package:github_explorer_starter/features/favorites/domain/favorite_user.dart';
import 'package:github_explorer_starter/features/favorites/domain/favorites_repository.dart';

class InMemoryFavoritesRepository implements FavoritesRepository {
  InMemoryFavoritesRepository([List<FavoriteUser> initial = const []])
    : _users = [...initial];

  final List<FavoriteUser> _users;
  bool failWrites = false;
  bool failReads = false;

  List<FavoriteUser> get stored => List.unmodifiable(_users);

  @override
  Future<List<FavoriteUser>> getAll() async {
    if (failReads) throw const StorageFailure('read failed');
    return [..._users]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  @override
  Future<void> save(FavoriteUser user) async {
    if (failWrites) throw const StorageFailure('write failed');
    _users
      ..removeWhere((u) => u.id == user.id)
      ..add(user);
  }

  @override
  Future<void> remove(int id) async {
    if (failWrites) throw const StorageFailure('write failed');
    _users.removeWhere((u) => u.id == id);
  }
}

Override favoritesOverride([FavoritesRepository? repository]) {
  final repo = repository ?? InMemoryFavoritesRepository();
  return favoritesRepositoryProvider.overrideWith((ref) => repo);
}

FavoriteUser favoriteUser(
  int id, {
  String? login,
  String? name,
  DateTime? addedAt,
}) {
  final userLogin = login ?? 'user$id';
  return FavoriteUser(
    id: id,
    login: userLogin,
    avatarUrl: '',
    htmlUrl: 'https://github.com/$userLogin',
    name: name,
    addedAt: addedAt ?? DateTime.utc(2026, 1, 1).add(Duration(minutes: id)),
  );
}
