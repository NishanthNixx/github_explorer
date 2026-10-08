import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeResponder = Future<ResponseBody> Function(RequestOptions options);

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.responder);

  FakeResponder responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    final response = responder(options);
    if (cancelFuture == null) return response;

    return Future.any([
      response,
      cancelFuture.then<ResponseBody>(
        (_) => throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelled',
        ),
      ),
    ]);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  Object? body,
  int statusCode, {
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

Dio buildTestDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter;
}
