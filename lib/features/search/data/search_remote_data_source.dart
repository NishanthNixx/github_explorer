import 'package:dio/dio.dart';

import '../../../core/network/cancellation_token.dart';
import 'models/search_users_response_dto.dart';

class SearchRemoteDataSource {
  const SearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SearchUsersResponseDto> searchUsers({
    required String query,
    required int page,
    required int perPage,
    CancellationToken? cancellationToken,
  }) async {
    final cancelToken = CancelToken();
    cancellationToken?.whenCancelled.then((_) => cancelToken.cancel());

    final response = await _dio.get<Object?>(
      '/search/users',
      queryParameters: {'q': query, 'page': page, 'per_page': perPage},
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException('Unexpected search response body', data);
    }
    return SearchUsersResponseDto.fromJson(data);
  }
}
