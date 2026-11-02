import 'dart:convert';
import 'dart:io';

/// Figma 接口调用失败（非 200）。
class FigmaHttpException implements Exception {
  FigmaHttpException({
    required this.statusCode,
    required this.url,
    this.retryAfter,
    this.body = '',
  });

  final int statusCode;
  final Uri url;
  final Duration? retryAfter;
  final String body;

  /// 额度受限（View/Collab 座位每月 20 次）。
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() {
    final hint = isRateLimited
        ? '（额度受限${retryAfter == null ? '' : '，${retryAfter!.inSeconds}s 后重试'}；'
            'View/Collab 座位每月 20 次 Tier 1，不要自动重试）'
        : '';
    return 'HTTP $statusCode from $url$hint';
  }
}

/// Figma REST 的最小客户端抽象：测试注入 fake，不联网、不消耗额度。
abstract class FigmaClient {
  /// 发起 GET 并返回解析后的 JSON；失败抛 [FigmaHttpException]。
  Future<Map<String, dynamic>> getJson(Uri url);

  void close() {}
}

/// 真实实现：只发 GET，令牌走 `X-Figma-Token` 头（`figd_` 令牌用 Bearer 会 401）。
class HttpFigmaClient implements FigmaClient {
  HttpFigmaClient({required this.token, this.timeout = const Duration(seconds: 60)});

  final String token;
  final Duration timeout;
  final _client = HttpClient();

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    final request = await _client.getUrl(url).timeout(timeout);
    request.headers.set('X-Figma-Token', token);
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode != 200) {
      final retryHeader = response.headers.value('retry-after');
      throw FigmaHttpException(
        statusCode: response.statusCode,
        url: url,
        retryAfter: retryHeader == null ? null : Duration(seconds: int.tryParse(retryHeader) ?? 0),
        body: body,
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw FigmaHttpException(statusCode: 200, url: url, body: '返回的不是 JSON 对象');
    }
    return decoded;
  }

  @override
  void close() => _client.close(force: true);
}

/// 惰性创建真实 client：缓存命中时不会读 token / 建连接。
class LazyFigmaClient implements FigmaClient {
  LazyFigmaClient(this._factory);

  final FigmaClient Function() _factory;
  FigmaClient? _client;

  @override
  Future<Map<String, dynamic>> getJson(Uri url) {
    return (_client ??= _factory()).getJson(url);
  }

  @override
  void close() => _client?.close();
}
