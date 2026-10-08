import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../../../core/widgets/status_view.dart';
import '../providers/search_notifier.dart';
import '../providers/search_state.dart';
import '../widgets/search_field.dart';
import '../widgets/search_results_list.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Explorer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
              controller: _controller,
              onChanged: notifier.onQueryChanged,
              onSubmitted: notifier.submit,
            ),
          ),
          const Expanded(child: _SearchBody()),
        ],
      ),
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return switch (state) {
      SearchIdle() => const StatusView(
        icon: Icons.person_search_rounded,
        title: 'Search GitHub users',
        message: 'Start typing a username to see matching profiles.',
      ),
      SearchLoading() => const Center(child: CircularProgressIndicator()),
      SearchEmpty(:final query) => StatusView(
        icon: Icons.search_off_rounded,
        title: 'No users found',
        message: 'No GitHub users match "$query".',
      ),
      SearchError(:final failure) => FailureView(
        failure: failure,
        onRetry: ref.read(searchProvider.notifier).retry,
      ),
      SearchSuccess() => SearchResultsList(
        state: state,
        onLoadMore: ref.read(searchProvider.notifier).loadMore,
        onRetryLoadMore: ref.read(searchProvider.notifier).retryLoadMore,
        onUserTap: (user) => context.go(AppRoutes.searchUser(user.login)),
      ),
    };
  }
}
