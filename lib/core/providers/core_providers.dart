import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// App-wide HTTP client. Override in tests with `dioProvider.overrideWithValue`.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDioClient();
  ref.onDispose(dio.close);
  return dio;
});
