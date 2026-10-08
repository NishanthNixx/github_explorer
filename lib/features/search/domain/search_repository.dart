import '../../../core/network/cancellation_token.dart';
import 'search_result_page.dart';

abstract interface class SearchRepository {
  Future<SearchResultPage> searchUsers({
    required String query,
    required int page,
    int perPage = 30,
    CancellationToken? cancellationToken,
  });
}
