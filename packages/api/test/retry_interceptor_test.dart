import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  late Dio dio;
  late _SequenceAdapter adapter;
  late WApiClient client;

  setUp(() {
    adapter = _SequenceAdapter([500, 200]);
    dio = Dio(BaseOptions(baseUrl: 'https://retry.test'));
    dio.httpClientAdapter = adapter;
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
    );
    dio.interceptors.add(retry);
    retry.bindDio(dio);
    client = WApiClient(dio);
  });

  test('GET 500 后重试成功', () async {
    final user = await client.get('/user', decode: _userFromJson);

    expect(user.name, 'Ada');
    expect(adapter.calls, 2);
  });

  test('POST 不重试', () async {
    adapter = _SequenceAdapter([500]);
    dio.httpClientAdapter = adapter;

    await expectLater(
      client.post('/user', body: {'name': 'Ada'}),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.server,
        ),
      ),
    );
    expect(adapter.calls, 1);
  });

  test('达到 maxRetries 后停止并抛出最终错误', () async {
    adapter = _SequenceAdapter([500]);
    dio.httpClientAdapter = adapter;

    await expectLater(
      client.get('/user'),
      throwsA(isA<WApiException>()),
    );
    expect(adapter.calls, 3);
  });

  test('401 不重试，交给 WTokenInterceptor', () async {
    adapter = _SequenceAdapter([401]);
    dio.httpClientAdapter = adapter;

    await expectLater(
      client.get('/user'),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.unauthorized,
        ),
      ),
    );
    expect(adapter.calls, 1);
  });

  test('非重试状态码（404）不重试', () async {
    adapter = _SequenceAdapter([404]);
    dio.httpClientAdapter = adapter;

    await expectLater(
      client.get('/user'),
      throwsA(isA<WApiException>()),
    );
    expect(adapter.calls, 1);
  });

  test('onRetry 回调带 attempt', () async {
    final attempts = <int>[];
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
      onRetry: (attempt, error) => attempts.add(attempt),
    );
    final retryingDio = Dio(BaseOptions(baseUrl: 'https://retry-callback.test'));
    final callbackAdapter = _SequenceAdapter([500, 200]);
    retryingDio.httpClientAdapter = callbackAdapter;
    retryingDio.interceptors.add(retry);
    retry.bindDio(retryingDio);

    await WApiClient(retryingDio).get('/user');

    expect(attempts, [1]);
    expect(callbackAdapter.calls, 2);
  });

  test('maxRetries=0 不重试', () async {
    final retry = WRetryInterceptor(
      maxRetries: 0,
      baseDelay: Duration.zero,
      jitter: false,
    );
    final noRetryDio = Dio(BaseOptions(baseUrl: 'https://no-retry.test'));
    final noRetryAdapter = _SequenceAdapter([500]);
    noRetryDio.httpClientAdapter = noRetryAdapter;
    noRetryDio.interceptors.add(retry);
    retry.bindDio(noRetryDio);

    await expectLater(WApiClient(noRetryDio).get('/user'), throwsA(anything));

    expect(noRetryAdapter.calls, 1);
  });

  test('transformTimeout 属于可重试的网络错误', () async {
    final timeouts = Dio(BaseOptions(baseUrl: 'https://transform-timeout.test'));
    final adapter = _TransformTimeoutAdapter();
    timeouts.httpClientAdapter = adapter;
    final retry = WRetryInterceptor(
      maxRetries: 1,
      baseDelay: Duration.zero,
      jitter: false,
    );
    timeouts.interceptors.add(retry);
    retry.bindDio(timeouts);

    await expectLater(timeouts.get('/user'), throwsA(isA<DioException>()));
    expect(adapter.calls, 2);
  });

  test('DioRegistry 会自动绑定 WRetryInterceptor', () async {
    const baseUrl = 'https://retry-registry.test';
    final registry = DioRegistry.forBaseUrl(
      baseUrl,
      interceptors: [
        WRetryInterceptor(
          maxRetries: 2,
          baseDelay: Duration.zero,
          jitter: false,
        ),
      ],
    );
    registry.dio.httpClientAdapter = _SequenceAdapter([500, 200]);

    final user = await WApiClient(registry.dio).get(
      '/user',
      decode: _userFromJson,
    );

    expect(user.name, 'Ada');
    DioRegistry.dispose(baseUrl);
  });

  test('shouldRetry 返回 false 时不重试', () async {
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
      shouldRetry: (_) => false,
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-custom.test'));
    final localAdapter = _SequenceAdapter([500]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    await expectLater(WApiClient(localDio).get('/user'), throwsA(anything));

    expect(localAdapter.calls, 1);
  });

  test('等待期间取消后不再重试', () async {
    final token = CancelToken();
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: const Duration(milliseconds: 10),
      jitter: false,
      onRetry: (attempt, error) => token.cancel('cancelled during backoff'),
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-cancel.test'));
    final localAdapter = _SequenceAdapter([500, 200]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    await expectLater(
      WApiClient(localDio).get('/user', cancelToken: token),
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.canceled,
        ),
      ),
    );

    expect(localAdapter.calls, 1);
  });

  test('disableRetryExtraKey 对单条请求关闭重试', () async {
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-disable.test'));
    final localAdapter = _SequenceAdapter([500]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    await expectLater(
      localDio.get(
        '/user',
        options: Options(
          extra: {WRetryInterceptor.disableRetryExtraKey: true},
        ),
      ),
      throwsA(isA<DioException>()),
    );

    expect(localAdapter.calls, 1);
  });

  test('shouldRetry 抛异常时不重试', () async {
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
      shouldRetry: (_) => throw StateError('policy failed'),
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-throw.test'));
    final localAdapter = _SequenceAdapter([500]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    await expectLater(WApiClient(localDio).get('/user'), throwsA(anything));

    expect(localAdapter.calls, 1);
  });

  test('unknown 默认不重试，shouldRetry 可显式放行', () async {
    final defaultRetry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
    );
    final defaultDio = Dio(BaseOptions(baseUrl: 'https://retry-unknown.test'));
    final defaultAdapter = _UnknownErrorAdapter();
    defaultDio.httpClientAdapter = defaultAdapter;
    defaultDio.interceptors.add(defaultRetry);
    defaultRetry.bindDio(defaultDio);

    await expectLater(defaultDio.get('/user'), throwsA(isA<DioException>()));
    expect(defaultAdapter.calls, 1);

    final retryUnknown = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: Duration.zero,
      jitter: false,
      shouldRetry: (error) => error.type == DioExceptionType.unknown,
    );
    final retryDio = Dio(BaseOptions(baseUrl: 'https://retry-unknown-on.test'));
    final retryAdapter = _UnknownErrorAdapter();
    retryDio.httpClientAdapter = retryAdapter;
    retryDio.interceptors.add(retryUnknown);
    retryUnknown.bindDio(retryDio);

    await expectLater(retryDio.get('/user'), throwsA(isA<DioException>()));
    expect(retryAdapter.calls, 3);
  });

  test('退避期间取消会立即结束等待', () async {
    final token = CancelToken();
    final retry = WRetryInterceptor(
      maxRetries: 2,
      baseDelay: const Duration(seconds: 5),
      jitter: false,
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-cancel-wait.test'));
    final localAdapter = _SequenceAdapter([500]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    final request = WApiClient(localDio).get('/user', cancelToken: token);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    token.cancel('stop during backoff');

    final watch = Stopwatch()..start();
    await expectLater(
      request,
      throwsA(
        isA<WApiException>().having(
          (error) => error.kind,
          'kind',
          WApiErrorKind.canceled,
        ),
      ),
    );
    watch.stop();

    expect(localAdapter.calls, 1);
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('PUT multipart 500 后重试会 clone FormData', () async {
    final retry = WRetryInterceptor(
      maxRetries: 1,
      baseDelay: Duration.zero,
      jitter: false,
    );
    final localDio = Dio(BaseOptions(baseUrl: 'https://retry-form.test'));
    final localAdapter = _SequenceAdapter([500, 200]);
    localDio.httpClientAdapter = localAdapter;
    localDio.interceptors.add(retry);
    retry.bindDio(localDio);

    await WApiClient(localDio).put<void>(
      '/upload',
      body: WApiBody.multipart(
        files: {
          'file': MultipartFile.fromBytes([1, 2, 3]),
        },
      ),
      decode: WApiDecoders.none,
    );

    expect(localAdapter.calls, 2);
    expect(localAdapter.last?.data, isA<FormData>());
  });
}

_User _userFromJson(Object? json) => _User.fromJson(json as Map<String, dynamic>);

class _User {
  const _User({required this.id, required this.name});

  factory _User.fromJson(Map<String, dynamic> json) => _User(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this.statuses);

  final List<int> statuses;
  int calls = 0;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final index = calls < statuses.length ? calls : statuses.length - 1;
    final status = statuses[index];
    calls++;

    return ResponseBody.fromString(
      jsonEncode(
        status == 200 ? {'id': 1, 'name': 'Ada'} : {'error': 'request failed'},
      ),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnknownErrorAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.unknown,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TransformTimeoutAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.transformTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}
