import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = createDioClient();
  ref.onDispose(dio.close);
  return dio;
});
