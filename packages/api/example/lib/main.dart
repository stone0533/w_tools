import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
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
  final _logs = <String>[];

  String? _token = 'expired-token';
  String _lastResult = '点击按钮发起请求';

  @override
  void initState() {
    super.initState();
    WApiConfig.logDebugHandler = (message) {
      if (mounted) setState(() => _logs.insert(0, message.toString().trim()));
    };
    WApiConfig.logErrorHandler = (message) {
      if (mounted) setState(() => _logs.insert(0, 'ERROR: $message'));
    };

    _adapter = _DemoAdapter();
    _registry = DioRegistry.forBaseUrl(
      _baseUrl,
      interceptors: [
        WLogInterceptor(responseHeader: true),
        WTokenInterceptor(
          tokenGetter: () => _token,
          tokenClearer: () async => _token = null,
          tokenRefresher: () async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            _token = 'fresh-token';
            return _token;
          },
        ),
      ],
    );
    _registry.dio.httpClientAdapter = _adapter;
  }

  @override
  void dispose() {
    DioRegistry.dispose(_baseUrl);
    WApiConfig.logDebugHandler = null;
    WApiConfig.logErrorHandler = null;
    super.dispose();
  }

  Future<void> _request(String path, {bool resetToken = false}) async {
    if (resetToken) _token = 'expired-token';
    setState(() => _lastResult = '请求中：$path');

    try {
      final response = await _registry.dio.get<String>(path);
      if (!mounted) return;
      setState(() {
        _lastResult = '$path → ${response.statusCode}\n${response.data}';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _lastResult = '$path → 失败：${error.message}');
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'DioRegistry + WLogInterceptor + WTokenInterceptor',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
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
    );
  }
}

/// 模拟服务端：/secure 只在 fresh-token 时返回 200。
class _DemoAdapter implements HttpClientAdapter {
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
