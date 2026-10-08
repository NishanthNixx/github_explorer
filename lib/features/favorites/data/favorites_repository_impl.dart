import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/app_failure.dart';
import '../domain/favorite_user.dart';
import '../domain/favorites_repository.dart';
import 'models/favorite_user_record.dart';

final favoritesRepositoryProvider = FutureProvider<FavoritesRepository>((
  ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return FavoritesRepositoryImpl(database);
}, retry: (_, _) => null);

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._db);

  final DatabaseExecutor _db;

  @override
  Future<List<FavoriteUser>> getAll() => _guard(() async {
    final rows = await _db.query(
      AppDatabase.favoritesTable,
      orderBy: '${FavoriteUserRecord.addedAt} DESC',
    );
    return rows.map(FavoriteUserRecord.fromRow).toList(growable: false);
  });

  @override
  Future<void> save(FavoriteUser user) => _guard(() async {
    await _db.insert(
      AppDatabase.favoritesTable,
      FavoriteUserRecord.toRow(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  });

  @override
  Future<void> remove(int id) => _guard(() async {
    await _db.delete(
      AppDatabase.favoritesTable,
      where: '${FavoriteUserRecord.id} = ?',
      whereArgs: [id],
    );
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DatabaseException catch (e) {
      throw StorageFailure(e);
    }
  }
}
