import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_failure.dart';
import '../../../core/network/cancellation_token.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/user_detail.dart';
import '../domain/user_detail_repository.dart';
import 'user_detail_remote_data_source.dart';

final userDetailRepositoryProvider = Provider<UserDetailRepository>((ref) {
  return UserDetailRepositoryImpl(
    UserDetailRemoteDataSource(ref.watch(dioProvider)),
  );
});

class UserDetailRepositoryImpl implements UserDetailRepository {
  const UserDetailRepositoryImpl(this._remote);

  final UserDetailRemoteDataSource _remote;

  @override
  Future<UserDetail> getUser(
    String username, {
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw const RequestCancelledFailure();
    }

    try {
      final dto = await _remote.getUser(
        username,
        cancellationToken: cancellationToken,
      );
      return dto.toEntity();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException catch (e) {
      throw UnknownFailure(e);
    }
  }
}
