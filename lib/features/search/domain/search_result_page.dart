import 'dart:math';

import 'github_user.dart';

class SearchResultPage {
  const SearchResultPage({
    required this.users,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  static const int maxAccessibleResults = 1000;

  final List<GithubUser> users;
  final int totalCount;
  final int page;
  final int perPage;

  bool get isEmpty => users.isEmpty;

  bool get hasMore {
    if (users.length < perPage) return false;
    final reachable = min(totalCount, maxAccessibleResults);
    return page * perPage < reachable;
  }
}
