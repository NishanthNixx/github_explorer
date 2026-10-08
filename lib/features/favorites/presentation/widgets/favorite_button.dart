import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_failure.dart';
import '../providers/favorites_notifier.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    this.name,
  });

  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(id));

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        color: isFavorite ? Colors.amber.shade700 : null,
      ),
      onPressed: () => _toggle(context, ref),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(favoritesProvider.notifier)
          .toggle(
            id: id,
            login: login,
            avatarUrl: avatarUrl,
            htmlUrl: htmlUrl,
            name: name,
          );
    } on AppFailure {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't update favorites. Please try again."),
          ),
        );
    }
  }
}
