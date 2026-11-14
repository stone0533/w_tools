import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:w_tools_api/w_tools_api.dart';

void main() {
  runApp(const ApiExampleApp());
}

class ApiExampleApp extends StatelessWidget {
  const ApiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_api 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
      ),
      home: const ApiDemoPage(),
    );
  }
}

class ApiDemoPage extends StatefulWidget {
  const ApiDemoPage({super.key});

  @override
  State<ApiDemoPage> createState() => _ApiDemoPageState();
}

class _ApiDemoPageState extends State<ApiDemoPage> {
  static const _baseUrl = 'https://api.example.com';

  late final DioRegistry _registry;
  late final _DemoAdapter _adapter;
  late final _DemoRepository _repository;
  late final BaseOptions _previousBaseOptions;
  final _logs = <String>[];

  String? _token = 'expired-token';
  String _lastResult = '点击按钮发起请求';

  @override
  void initState() {
    super.initState();
    WApiSettings.logDebugHandler = (message) {
      if (mounted) setState(() => _logs.insert(0, message.toString().trim()));
    };
    WApiSettings.logErrorHandler = (message) {
      if (mounted) setState(() => _logs.insert(0, 'ERROR: $message'));
    };
    _previousBaseOptions = WApiSettings.baseOptions;
    WApiSettings.baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    );

    _adapter = _DemoAdapter();
    _registry = DioRegistry.forBaseUrl(
      _baseUrl,
      interceptors: [
        _DemoMetaInterceptor(
          onErrorObserved: (status) {
            if (mounted) setState(() => _logs.insert(0, 'observed: $status'));
          },
        ),
        WTokenInterceptor(
          tokenGetter: () => _token,
          tokenClearer: () async => _token = null,
          tokenRefresher: () async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            _token = 'fresh-token';
            return _token;
          },
        ),
        WLogInterceptor(
          parts: {
            WLogPart.request,
            WLogPart.requestHeader,
            WLogPart.responseHeader,
            WLogPart.error,
          },
          redactedHeaders: {
            ...WLogInterceptor.defaultRedactedHeaders,
            'x-demo-secret',
          },
        ),
        // 只对 /flaky 重试，避免影响 /error 的 500 错误演示。
        WRetryInterceptor(
          maxRetries: 2,
          baseDelay: Duration.zero,
          jitter: false,
          shouldRetry: (error) => error.requestOptions.path == '/flaky',
        ),
      ],
    );
    _registry.dio.httpClientAdapter = _adapter;
    _repository = _DemoRepository(
      localDataSource: _DemoLocalDataSource(),
      remoteDataSource: _DemoRemoteDataSource(_registry.dio),
    );
  }

  @override
  void dispose() {
    DioRegistry.dispose(_baseUrl);
    WApiSettings.baseOptions = _previousBaseOptions;
    WApiSettings.logDebugHandler = null;
    WApiSettings.logErrorHandler = null;
    super.dispose();
  }

  Future<void> _request(String path, {bool resetToken = false}) async {
    if (resetToken) _token = 'expired-token';
    setState(() => _lastResult = '请求中：$path');

    try {
      final response = await _registry.dio.get<String>(
        path,
        options: path == '/public' ? Options(headers: {'X-Demo-Secret': 'demo-secret'}) : null,
      );
      if (!mounted) return;
      setState(() {
        _lastResult =
            '$path → ${response.statusCode}\n'
            'client: ${response.extra['demoClient']}\n'
            '${response.data}';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _lastResult = '$path → 失败：${error.message}');
    }
  }

  Future<void> _loadRepository() async {
    setState(() => _lastResult = 'Repository 加载中');
    final value = await _repository.load();
    if (!mounted) return;
    setState(() {
      _lastResult =
          'Repository: $value\n'
          'local cache: ${_repository.localDataSource?.cached}';
    });
  }

  Future<void> _loadPage() async {
    setState(() => _lastResult = '分页加载中');
    try {
      final json = await WApiClient(_registry.dio).get<Map<String, dynamic>>(
        '/page',
        query: const {'page': 1, 'pageSize': 2},
      );
      final items = (json['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(_DemoUser.fromJson)
          .toList();
      final total = json['total'] as int?;
      final hasMore = total == null ? items.length >= 2 : 2 < total;
      if (!mounted) return;
      setState(() {
        _lastResult =
            'page → ${items.length} 条\n'
            'hasMore: $hasMore\n'
            '${items.map((user) => user.name).join(', ')}';
      });
    } on WApiException catch (error) {
      if (!mounted) return;
      setState(() => _lastResult = '分页失败：${error.kind.name}');
    }
  }

  Future<void> _upload() async {
    setState(() => _lastResult = '上传中');
    try {
      await WApiClient(_registry.dio).upload<void>(
        '/upload',
        fields: const {'bucket': 'avatar'},
        files: {
          'file': MultipartFile.fromBytes([1, 2, 3], filename: 'demo.bin'),
        },
        decode: WApiDecoders.none,
      );
      if (!mounted) return;
      setState(() => _lastResult = '上传成功');
    } on WApiException catch (error) {
      if (!mounted) return;
      setState(() => _lastResult = '上传失败：${error.kind.name}');
    }
  }

  Future<void> _retryRequest() async {
    setState(() => _lastResult = '重试请求中');
    try {
      final response = await _registry.dio.get<Map<String, dynamic>>('/flaky');
      if (!mounted) return;
      setState(() {
        _lastResult =
            '/flaky → ${response.statusCode}\n'
            'attempt: ${response.data?['attempt']}';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _lastResult = '/flaky → 失败：${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 拦截器'),
        actions: [
          IconButton(
            tooltip: '清空日志',
            onPressed: () => setState(_logs.clear),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DioRegistry + WLogInterceptor + WTokenInterceptor',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('baseUrl：$_baseUrl'),
            Text('当前 token：${_token ?? 'null'}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _request('/public'),
                  child: const Text('GET /public'),
                ),
                FilledButton.tonal(
                  onPressed: () => _request('/secure', resetToken: true),
                  child: const Text('401 → 刷新 → 重试'),
                ),
                OutlinedButton(
                  onPressed: () => _request('/error'),
                  child: const Text('GET /error（500）'),
                ),
                OutlinedButton(
                  onPressed: _loadRepository,
                  child: const Text('Repository 缓存'),
                ),
                FilledButton.tonal(
                  onPressed: _loadPage,
                  child: const Text('分页'),
                ),
                OutlinedButton(
                  onPressed: _upload,
                  child: const Text('上传'),
                ),
                OutlinedButton(
                  onPressed: _retryRequest,
                  child: const Text('500 重试'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _lastResult,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('日志', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_logs.isEmpty)
              const Text('暂无日志')
            else
              ..._logs.map(
                (log) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoUser {
  const _DemoUser({required this.id, required this.name});

  factory _DemoUser.fromJson(Map<String, dynamic> json) => _DemoUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
  );

  final int id;
  final String name;
}

class _DemoLocalDataSource {
  String? cached;
}

class _DemoRemoteDataSource {
  _DemoRemoteDataSource(this.dio);

  final Dio dio;

  Future<String> fetch() async {
    final response = await dio.get<String>('/public');
    return response.data ?? '';
  }
}

class _DemoRepository {
  _DemoRepository({this.localDataSource, this.remoteDataSource});

  final _DemoLocalDataSource? localDataSource;
  final _DemoRemoteDataSource? remoteDataSource;

  Future<String> load() async {
    final value = await remoteDataSource!.fetch();
    localDataSource!.cached = value;
    return value;
  }
}

/// 示例：不属于 token 职责的公共 header / 响应标记 / 错误观测，用普通拦截器实现。
class _DemoMetaInterceptor extends Interceptor {
  _DemoMetaInterceptor({this.onErrorObserved});

  final void Function(int? status)? onErrorObserved;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Demo-Client'] = 'api-example';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    response.extra['demoClient'] = 'w_tools_api';
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    onErrorObserved?.call(err.response?.statusCode);
    handler.next(err);
  }
}

/// 模拟服务端：/secure 只在 fresh-token 时返回 200，/flaky 首次 500 后成功。
class _DemoAdapter implements HttpClientAdapter {
  int _flakyCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization']?.toString();
    if (options.path == '/secure' && auth != 'Bearer fresh-token') {
      return ResponseBody.fromString(
        jsonEncode({'error': 'unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'set-cookie': ['session=secret'],
        },
      );
    }

    if (options.path == '/error') {
      return ResponseBody.fromString(
        jsonEncode({'error': 'server error'}),
        500,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'set-cookie': ['session=secret'],
        },
      );
    }

    if (options.path == '/flaky') {
      _flakyCalls++;
      if (_flakyCalls == 1) {
        return ResponseBody.fromString(
          jsonEncode({'error': 'temporary'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'ok': true, 'attempt': _flakyCalls}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path == '/page') {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [
            {'id': 1, 'name': 'Ada'},
            {'id': 2, 'name': 'Grace'},
          ],
          'total': 3,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path == '/upload') {
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'path': options.path,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        'set-cookie': ['session=secret'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
