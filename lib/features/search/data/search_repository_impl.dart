import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_failure.dart';
import '../../../core/network/cancellation_token.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/search_repository.dart';
import '../domain/search_result_page.dart';
import 'search_remote_data_source.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(SearchRemoteDataSource(ref.watch(dioProvider)));
});

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<SearchResultPage> searchUsers({
    required String query,
    required int page,
    int perPage = 30,
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw const RequestCancelledFailure();
    }

    try {
      final dto = await _remote.searchUsers(
        query: query,
        page: page,
        perPage: perPage,
        cancellationToken: cancellationToken,
      );
      return SearchResultPage(
        users: dto.items.map((item) => item.toEntity()).toList(growable: false),
        totalCount: dto.totalCount,
        page: page,
        perPage: perPage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw UnknownFailure(e);
    }
  }
}
