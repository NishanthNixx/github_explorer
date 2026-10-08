import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/database/app_database.dart';
import 'package:github_explorer_starter/features/favorites/data/favorites_repository_impl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fake_favorites_repository.dart';

void main() {
  late Directory tempDir;
  late String dbPath;
  late Database db;
  late FavoritesRepositoryImpl repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('favorites_test');
    dbPath = p.join(tempDir.path, AppDatabase.fileName);
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: dbPath);
    repository = FavoritesRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('starts empty', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('saves and reads back every field', () async {
    final user = favoriteUser(
      583231,
      login: 'octocat',
      name: 'The Octocat',
      addedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
    );

    await repository.save(user);

    expect(await repository.getAll(), [user]);
  });

  test('returns the most recently added first', () async {
    await repository.save(favoriteUser(1, addedAt: DateTime.utc(2026, 1, 1)));
    await repository.save(favoriteUser(2, addedAt: DateTime.utc(2026, 1, 3)));
    await repository.save(favoriteUser(3, addedAt: DateTime.utc(2026, 1, 2)));

    final ids = (await repository.getAll()).map((u) => u.id);
    expect(ids, [2, 3, 1]);
  });

  test('saving the same user again updates instead of duplicating', () async {
    await repository.save(favoriteUser(1, login: 'octocat'));
    await repository.save(
      favoriteUser(1, login: 'octocat', name: 'The Octocat'),
    );

    final all = await repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'The Octocat');
  });

  test('removes by id', () async {
    await repository.save(favoriteUser(1));
    await repository.save(favoriteUser(2));

    await repository.remove(1);

    expect((await repository.getAll()).map((u) => u.id), [2]);
  });

  test('removing a missing id is a no-op', () async {
    await repository.save(favoriteUser(1));

    await repository.remove(999);

    expect(await repository.getAll(), hasLength(1));
  });

  test('favorites survive closing and reopening the database', () async {
    final user = favoriteUser(7, login: 'hubot', name: 'Hubot');
    await repository.save(user);
    await db.close();

    db = await AppDatabase.open(factory: databaseFactoryFfi, path: dbPath);
    repository = FavoritesRepositoryImpl(db);

    expect(await repository.getAll(), [user]);
    expect(await db.getVersion(), AppDatabase.version);
  });
}
