import 'package:flutter_test/flutter_test.dart';
import 'package:github_explorer_starter/features/search/domain/github_user.dart';
import 'package:github_explorer_starter/features/search/domain/search_result_page.dart';

void main() {
  List<GithubUser> users(int count) => List.generate(
    count,
    (i) => GithubUser(
      id: i,
      login: 'user$i',
      avatarUrl: '',
      htmlUrl: 'https://github.com/user$i',
    ),
  );

  SearchResultPage page({
    required int page,
    required int returned,
    required int total,
    int perPage = 30,
  }) {
    return SearchResultPage(
      users: users(returned),
      totalCount: total,
      page: page,
      perPage: perPage,
    );
  }

  test('has more when a full page is returned and results remain', () {
    expect(page(page: 1, returned: 30, total: 100).hasMore, isTrue);
  });

  test('no more when the page is not full', () {
    expect(page(page: 4, returned: 10, total: 100).hasMore, isFalse);
  });

  test('no more when the last page exactly reaches total_count', () {
    expect(page(page: 2, returned: 30, total: 60).hasMore, isFalse);
  });

  test('stops at the 1000 result search cap even if total_count is higher', () {
    expect(
      page(page: 10, returned: 100, total: 50000, perPage: 100).hasMore,
      isFalse,
    );
    expect(
      page(page: 9, returned: 100, total: 50000, perPage: 100).hasMore,
      isTrue,
    );
  });

  test('empty page reports isEmpty and no more', () {
    final result = page(page: 1, returned: 0, total: 0);

    expect(result.isEmpty, isTrue);
    expect(result.hasMore, isFalse);
  });
}
