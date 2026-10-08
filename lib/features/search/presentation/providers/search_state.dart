import '../../../../core/network/app_failure.dart';
import '../../domain/github_user.dart';

sealed class SearchState {
  const SearchState();
}

final class SearchIdle extends SearchState {
  const SearchIdle();
}

final class SearchLoading extends SearchState {
  const SearchLoading(this.query);

  final String query;
}

final class SearchSuccess extends SearchState {
  const SearchSuccess({
    required this.query,
    required this.users,
    required this.totalCount,
    required this.page,
    required this.hasMore,
  });

  final String query;
  final List<GithubUser> users;
  final int totalCount;
  final int page;
  final bool hasMore;
}

final class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);

  final String query;
}

final class SearchError extends SearchState {
  const SearchError(this.query, this.failure);

  final String query;
  final AppFailure failure;
}
