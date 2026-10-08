import 'package:flutter/material.dart';

import '../../../../core/network/app_failure.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/github_user.dart';
import '../../domain/search_result_page.dart';
import '../providers/search_state.dart';
import 'user_list_tile.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.onRetryLoadMore,
    this.onUserTap,
    this.trailingBuilder,
  });

  final SearchSuccess state;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryLoadMore;
  final ValueChanged<GithubUser>? onUserTap;
  final Widget Function(GithubUser user)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final users = state.users;
    final footer = _buildFooter();

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: users.length + (footer == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index < users.length) {
          final user = users[index];
          final onUserTap = this.onUserTap;
          return UserListTile(
            key: ValueKey(user.id),
            user: user,
            onTap: onUserTap == null ? null : () => onUserTap(user),
            trailing: trailingBuilder?.call(user),
          );
        }
        return footer;
      },
    );
  }

  Widget? _buildFooter() {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return _LoadMoreError(failure: failure, onRetry: onRetryLoadMore);
    }
    if (state.hasMore) {
      return _LoadMoreTrigger(onVisible: onLoadMore);
    }
    if (state.isCapped) {
      return const _EndNote(
        'Showing the first ${SearchResultPage.maxAccessibleResults} results. '
        'Refine your search to narrow it down.',
      );
    }
    return null;
  }
}

class _LoadMoreTrigger extends StatefulWidget {
  const _LoadMoreTrigger({required this.onVisible});

  final VoidCallback onVisible;

  @override
  State<_LoadMoreTrigger> createState() => _LoadMoreTriggerState();
}

class _LoadMoreTriggerState extends State<_LoadMoreTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, _) = FailureView.describe(failure, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't load more: $title",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EndNote extends StatelessWidget {
  const _EndNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
