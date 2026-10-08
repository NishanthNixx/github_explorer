import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/core/network/app_failure.dart';
import 'package:github_explorer_starter/features/favorites/domain/favorite_user.dart';
import 'package:github_explorer_starter/features/favorites/presentation/providers/favorites_notifier.dart';

import '../../../../helpers/fake_favorites_repository.dart';

void main() {
  late InMemoryFavoritesRepository repository;
  late ProviderContainer container;

  void setUpContainer([List<FavoriteUser> initial = const []]) {
    repository = InMemoryFavoritesRepository(initial);
    container = ProviderContainer(overrides: [favoritesOverride(repository)]);
    addTearDown(container.dispose);
    container.listen(favoritesProvider, (_, _) {});
  }

  FavoritesNotifier notifier() => container.read(favoritesProvider.notifier);

  Future<void> toggle(int id, {String? name}) => notifier().toggle(
    id: id,
    login: 'user$id',
    avatarUrl: '',
    htmlUrl: 'https://github.com/user$id',
    name: name,
  );

  test('loads saved favorites newest first', () async {
    setUpContainer([favoriteUser(1), favoriteUser(2)]);

    final users = await container.read(favoritesProvider.future);

    expect(users.map((u) => u.id), [2, 1]);
  });

  test('toggle adds a user at the top and persists it', () async {
    setUpContainer([favoriteUser(1)]);
    await container.read(favoritesProvider.future);
    final now = DateTime.utc(2026, 10, 8, 9);

    await withClock(Clock.fixed(now), () => toggle(5, name: 'Five'));

    final users = container.read(favoritesProvider).requireValue;
    expect(users.map((u) => u.id), [5, 1]);
    expect(users.first.name, 'Five');
    expect(users.first.addedAt, now);
    expect(repository.stored.map((u) => u.id), containsAll([1, 5]));
  });

  test('toggle removes an existing favorite and persists it', () async {
    setUpContainer([favoriteUser(1), favoriteUser(2)]);
    await container.read(favoritesProvider.future);

    await toggle(1);

    expect(container.read(favoritesProvider).requireValue.map((u) => u.id), [
      2,
    ]);
    expect(repository.stored.map((u) => u.id), [2]);
  });

  test('isFavoriteProvider follows toggles', () async {
    setUpContainer();
    await container.read(favoritesProvider.future);

    expect(container.read(isFavoriteProvider(3)), isFalse);
    await toggle(3);
    expect(container.read(isFavoriteProvider(3)), isTrue);
    await toggle(3);
    expect(container.read(isFavoriteProvider(3)), isFalse);
  });

  test('a failed save rolls back the optimistic add', () async {
    setUpContainer();
    await container.read(favoritesProvider.future);
    repository.failWrites = true;

    await expectLater(toggle(3), throwsA(isA<StorageFailure>()));

    expect(container.read(favoritesProvider).requireValue, isEmpty);
    expect(container.read(isFavoriteProvider(3)), isFalse);
  });

  test('a failed remove restores the user in its original position', () async {
    setUpContainer([favoriteUser(1), favoriteUser(2), favoriteUser(3)]);
    await container.read(favoritesProvider.future);
    repository.failWrites = true;

    await expectLater(toggle(2), throwsA(isA<StorageFailure>()));

    expect(container.read(favoritesProvider).requireValue.map((u) => u.id), [
      3,
      2,
      1,
    ]);
  });

  test('a failed load surfaces a StorageFailure', () async {
    repository = InMemoryFavoritesRepository()..failReads = true;
    container = ProviderContainer(overrides: [favoritesOverride(repository)]);
    addTearDown(container.dispose);

    await expectLater(
      container.read(favoritesProvider.future),
      throwsA(isA<StorageFailure>()),
    );
  });
}
