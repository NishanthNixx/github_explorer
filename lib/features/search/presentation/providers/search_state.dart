import '../../../../core/network/app_failure.dart';
import '../../domain/github_user.dart';
import '../../domain/search_result_page.dart';

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
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final String query;
  final List<GithubUser> users;
  final int totalCount;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final AppFailure? loadMoreFailure;

  bool get isCapped =>
      !hasMore && totalCount > SearchResultPage.maxAccessibleResults;

  SearchSuccess copyWith({
    List<GithubUser>? users,
    int? totalCount,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    AppFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) {
    return SearchSuccess(
      query: query,
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : loadMoreFailure ?? this.loadMoreFailure,
    );
  }
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
