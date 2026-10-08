import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_impl.dart';
import '../../domain/account.dart';

final accountProvider = FutureProvider.autoDispose<Account>(
  (ref) => ref.watch(authRepositoryProvider).fetchAccount(),
  retry: (_, _) => null,
);
