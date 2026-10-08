import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final appDatabaseProvider = FutureProvider<Database>((ref) async {
  final database = await AppDatabase.open();
  ref.onDispose(database.close);
  return database;
}, retry: (_, _) => null);

abstract final class AppDatabase {
  static const String fileName = 'github_explorer.db';
  static const int version = 1;

  static const String favoritesTable = 'favorites';

  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final databasePath =
        path ?? p.join(await dbFactory.getDatabasesPath(), fileName);

    return dbFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _migrate(db, from: 0, to: version);
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    await _migrate(db, from: from, to: to);
  }

  static Future<void> _migrate(
    Database db, {
    required int from,
    required int to,
  }) async {
    final batch = db.batch();
    if (from < 1 && to >= 1) {
      batch.execute('''
        CREATE TABLE $favoritesTable (
          id INTEGER PRIMARY KEY,
          login TEXT NOT NULL UNIQUE,
          avatar_url TEXT NOT NULL,
          html_url TEXT NOT NULL,
          name TEXT,
          added_at INTEGER NOT NULL
        )
      ''');
      batch.execute(
        'CREATE INDEX idx_favorites_added_at ON $favoritesTable (added_at DESC)',
      );
    }
    await batch.commit(noResult: true);
  }
}
