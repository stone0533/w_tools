import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_api/w_tools_api.dart';

/// 401 之后的行为：只有带「刷新后的 token」才放行
class _RaceAdapter implements HttpClientAdapter {
  _RaceAdapter(this.newToken);

  final String newToken;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (options.path == '/slow') {
      // 让第二个 401 在第一次刷新完成之后才回来
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    final auth = options.headers['Authorization'];
    final authorized = auth == 'Bearer $newToken';
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(authorized ? '{"ok":true}' : '{"error":401}'))),
      authorized ? 200 : 401,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(DioRegistry.clearCache);

  test('并发 401：晚到的那个不应清掉刚刷新的 token，也不应再次刷新', () async {
    const base = 'https://race.example.com';
    var token = 'old';
    var refreshes = 0;

    final registry = DioRegistry.forBaseUrl(base);
    registry.dio.httpClientAdapter = _RaceAdapter('new-1');
    registry.dio.interceptors.add(
      WTokenInterceptor(
        dio: registry.dio,
        tokenGetter: () => token,
        tokenClearer: () async => token = '',
        tokenRefresher: () async {
          refreshes++;
          token = 'new-$refreshes';
          return token;
        },
      ),
    );

    final results = await Future.wait([
      registry.dio.get<dynamic>('/fast').then((r) => r.statusCode).catchError((_) => -1),
      registry.dio.get<dynamic>('/slow').then((r) => r.statusCode).catchError((_) => -1),
    ]);

    expect(results, [200, 200], reason: '两个请求都应带着刷新后的 token 重试成功');
    expect(refreshes, 1, reason: '晚到的 401 不应再触发一次刷新');
    expect(token, 'new-1', reason: '晚到的 401 不应把刚写入的新 token 清掉');
  });
}
