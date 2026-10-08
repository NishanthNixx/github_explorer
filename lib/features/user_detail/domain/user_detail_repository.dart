import '../../../core/network/cancellation_token.dart';
import 'user_detail.dart';

abstract interface class UserDetailRepository {
  Future<UserDetail> getUser(
    String username, {
    CancellationToken? cancellationToken,
  });
}
