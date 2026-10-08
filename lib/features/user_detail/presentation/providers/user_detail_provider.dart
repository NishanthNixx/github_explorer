import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/cancellation_token.dart';
import '../../data/user_detail_repository_impl.dart';
import '../../domain/user_detail.dart';

final userDetailProvider = FutureProvider.autoDispose
    .family<UserDetail, String>((ref, username) {
      final token = CancellationToken();
      ref.onDispose(token.cancel);
      return ref
          .watch(userDetailRepositoryProvider)
          .getUser(username, cancellationToken: token);
    }, retry: (_, _) => null);
