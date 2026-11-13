import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

class _Always401 implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":"unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(DioRegistry.clearCache);

  test('API-009 refresh 失败时调用 onAuthFailure', () async {
    var failures = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://auth-failure.example.com'))
      ..httpClientAdapter = _Always401();
    dio.interceptors.add(
      WTokenInterceptor(
        dio: dio,
        tokenGetter: () => 'expired',
        tokenRefresher: () async => null,
        onAuthFailure: (error) {
          failures++;
          expect(error.response?.statusCode, 401);
        },
      ),
    );

    await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
    expect(failures, 1);
  });

  test('API-024 WApiConfig.reset 恢复默认值', () {
    WApiConfig.baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 1),
      receiveTimeout: const Duration(seconds: 2),
    );
    WApiConfig.logDebugHandler = (_) {};
    WApiConfig.logErrorHandler = (_) {};

    WApiConfig.reset();

    expect(
      WApiConfig.baseOptions.connectTimeout,
      const Duration(milliseconds: 10000),
    );
    expect(
      WApiConfig.baseOptions.receiveTimeout,
      const Duration(milliseconds: 50000),
    );
    expect(WApiConfig.logDebugHandler, isNull);
    expect(WApiConfig.logErrorHandler, isNull);
  });
}
