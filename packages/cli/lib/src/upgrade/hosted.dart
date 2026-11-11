import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'upgrade_plan.dart';

/// hosted 源的默认地址；与 pub 一致，允许用 `PUB_HOSTED_URL` 换镜像。
const defaultHostedUrl = 'https://pub.dev';

/// hosted 源不可用（网络 / 代理 / 非 200 / 返回体不是 JSON）。
class HostedException implements Exception {
  const HostedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 查最新版本；测试注入假实现，命令层不直接碰网络。
abstract class LatestFetcher {
  String get hosted;

  Future<Map<String, LatestRelease?>> fetch(Iterable<String> names);
}

/// `--hosted` > `PUB_HOSTED_URL` > pub.dev；去掉尾部斜杠。
String resolveHostedUrl({String? override, Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final raw = (override ?? env['PUB_HOSTED_URL'] ?? defaultHostedUrl).trim();
  if (raw.isEmpty) return defaultHostedUrl;
  return raw.replaceFirst(RegExp(r'/+$'), '');
}

class HttpLatestFetcher implements LatestFetcher {
  HttpLatestFetcher({
    String? hosted,
    Map<String, String>? environment,
    this.timeout = const Duration(seconds: 8),
  }) : hosted = resolveHostedUrl(override: hosted, environment: environment) {
    _client = HttpClient()
      ..connectionTimeout = timeout
      // pub 自己不读系统代理；办公室网段下不设这一行会表现为「命令无输出卡住」。
      ..findProxy = HttpClient.findProxyFromEnvironment;
  }

  @override
  final String hosted;

  final Duration timeout;
  late final HttpClient _client;

  @override
  Future<Map<String, LatestRelease?>> fetch(Iterable<String> names) async {
    final result = <String, LatestRelease?>{};
    // 包数量是个位数，直接并发；单个失败就让整条命令失败，不返回半份数据。
    await Future.wait(<Future<void>>[
      for (final name in names)
        () async {
          result[name] = await _fetchOne(name);
        }(),
    ]);
    return result;
  }

  void close() => _client.close(force: true);

  Future<LatestRelease?> _fetchOne(String name) async {
    final uri = Uri.parse('$hosted/api/packages/$name');
    try {
      final request = await _client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain<void>();
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HostedException('$hosted 返回 HTTP ${response.statusCode}（$name）');
      }
      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      final json = jsonDecode(body);
      if (json is! Map<String, Object?>) {
        throw HostedException('$hosted 的 $name 响应结构不对（不是 JSON 对象）');
      }
      return _parse(name, json);
    } on HostedException {
      rethrow;
    } on SocketException catch (e) {
      throw HostedException('连不上 $hosted：${e.message}');
    } on TimeoutException {
      throw HostedException('请求 $hosted 超时（${timeout.inSeconds}s，$name）');
    } on HttpException catch (e) {
      throw HostedException('请求 $hosted 失败：${e.message}');
    } on FormatException catch (e) {
      throw HostedException('$hosted 的 $name 响应不是合法 JSON：${e.message}');
    }
  }

  LatestRelease? _parse(String name, Map<String, Object?> json) {
    final latest = json['latest'];
    if (latest is! Map<String, Object?>) return null;
    final version = latest['version'];
    if (version is! String) return null;
    final pubspec = latest['pubspec'];
    final environment = pubspec is Map<String, Object?> ? pubspec['environment'] : null;
    String? read(String key) {
      final value = environment is Map<String, Object?> ? environment[key] : null;
      return value is String ? value : null;
    }

    return LatestRelease(
      version: version,
      sdkConstraint: read('sdk'),
      flutterConstraint: read('flutter'),
      published: latest['published'] is String ? latest['published'] as String : null,
    );
  }
}
