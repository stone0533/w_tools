import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  late Dio dio;
  late _Adapter adapter;
  late List<WMetric> metrics;
  late WMetricsInterceptor interceptor;

  setUp(() {
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://metrics.test'));
    dio.httpClientAdapter = adapter;
    metrics = <WMetric>[];
    interceptor = WMetricsInterceptor(onMetric: metrics.add);
    dio.interceptors.add(interceptor);
  });

  test('成功请求记录 method / path / status / duration', () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {'token': 'secret'},
    );

    expect(response.statusCode, 200);
    expect(metrics, hasLength(1));
    expect(metrics.single.method, 'GET');
    expect(metrics.single.path, '/users');
    expect(metrics.single.uri.query, contains('token=secret'));
    expect(metrics.single.statusCode, 200);
    expect(metrics.single.failed, isFalse);
    expect(metrics.single.duration.inMicroseconds, greaterThanOrEqualTo(0));
  });

  test('失败请求记录 failed / error / status', () async {
    adapter.handler = (_) => _json(500, {'error': 'boom'});

    await expectLater(dio.get('/error'), throwsA(anything));

    expect(metrics, hasLength(1));
    expect(metrics.single.failed, isTrue);
    expect(metrics.single.statusCode, 500);
    expect(metrics.single.error, isA<DioException>());
  });

  test('sampleRate=0 不产生指标', () async {
    dio.interceptors.clear();
    dio.interceptors.add(
      WMetricsInterceptor(onMetric: metrics.add, sampleRate: 0),
    );

    await dio.get('/users');

    expect(metrics, isEmpty);
  });

  test('自定义 validateStatus 接受 4xx 时 failed 仍按状态判定', () async {
    adapter.handler = (_) => _json(404, {'error': 'missing'});

    await dio.get(
      '/missing',
      options: Options(validateStatus: (_) => true),
    );

    expect(metrics, hasLength(1));
    expect(metrics.single.statusCode, 404);
    expect(metrics.single.failed, isTrue);
  });

  test('重试时每次尝试的 attempt 递增', () async {
    var calls = 0;
    adapter.handler = (_) {
      calls++;
      return _json(calls == 1 ? 500 : 200, {'ok': true});
    };

    dio.interceptors.clear();
    final retry = WRetryInterceptor(
      maxRetries: 1,
      baseDelay: Duration.zero,
      jitter: false,
    );
    // metrics 放在 retry 之前：请求方向先启动计时，错误方向先产出当次 metric。
    dio.interceptors.add(WMetricsInterceptor(onMetric: metrics.add));
    dio.interceptors.add(retry);
    retry.bindDio(dio);

    await dio.get('/retry');

    expect(metrics.map((metric) => metric.attempt), [1, 2]);
    expect(metrics.first.failed, isTrue);
    expect(metrics.last.failed, isFalse);
  });

  test('onMetric 抛异常不影响请求', () async {
    dio.interceptors.clear();
    dio.interceptors.add(
      WMetricsInterceptor(
        onMetric: (_) => throw StateError('metrics failure'),
      ),
    );

    final response = await dio.get('/users');

    expect(response.statusCode, 200);
  });
}

class _Adapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler?.call(options) ?? _json(200, {'ok': true});

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
