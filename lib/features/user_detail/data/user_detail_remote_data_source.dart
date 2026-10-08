import 'package:dio/dio.dart';

import '../../../core/network/cancellation_token.dart';
import 'models/user_detail_dto.dart';

class UserDetailRemoteDataSource {
  const UserDetailRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserDetailDto> getUser(
    String username, {
    CancellationToken? cancellationToken,
  }) async {
    final cancelToken = CancelToken();
    cancellationToken?.whenCancelled.then((_) => cancelToken.cancel());

    final response = await _dio.get<Object?>(
      '/users/${Uri.encodeComponent(username)}',
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException('Unexpected user detail response body', data);
    }
    return UserDetailDto.fromJson(data);
  }
}
