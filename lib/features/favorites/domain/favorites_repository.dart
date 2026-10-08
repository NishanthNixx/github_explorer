import 'favorite_user.dart';

abstract interface class FavoritesRepository {
  Future<List<FavoriteUser>> getAll();

  Future<void> save(FavoriteUser user);

  Future<void> remove(int id);
}
