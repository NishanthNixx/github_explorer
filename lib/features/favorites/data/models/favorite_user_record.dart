import '../../domain/favorite_user.dart';

abstract final class FavoriteUserRecord {
  static const String id = 'id';
  static const String login = 'login';
  static const String avatarUrl = 'avatar_url';
  static const String htmlUrl = 'html_url';
  static const String name = 'name';
  static const String addedAt = 'added_at';

  static Map<String, Object?> toRow(FavoriteUser user) => {
    id: user.id,
    login: user.login,
    avatarUrl: user.avatarUrl,
    htmlUrl: user.htmlUrl,
    name: user.name,
    addedAt: user.addedAt.toUtc().millisecondsSinceEpoch,
  };

  static FavoriteUser fromRow(Map<String, Object?> row) {
    return FavoriteUser(
      id: row[id]! as int,
      login: row[login]! as String,
      avatarUrl: row[avatarUrl]! as String,
      htmlUrl: row[htmlUrl]! as String,
      name: row[name] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        row[addedAt]! as int,
        isUtc: true,
      ),
    );
  }
}
