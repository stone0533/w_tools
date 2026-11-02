import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';

/// 用 fake client 测 fetch / init / usage / url：不联网、不消耗额度。
class FakeClient implements FigmaClient {
  FakeClient(this.payload);

  final Map<String, dynamic> payload;
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    return payload;
  }

  @override
  void close() {}
}

class FailingClient implements FigmaClient {
  FailingClient(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async => throw error;

  @override
  void close() {}
}

void main() {
  late Directory root;
  late CacheStore store;
  const payload = {
    'nodes': {
      '1:2': {
        'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'}
      },
    },
  };

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_test_');
    store = CacheStore(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('fetch', () {
    test('首次请求写缓存与用量日志，第二次命中缓存不再请求', () async {
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);

      final first = await command.nodes(fileKey: 'K', ids: ['1:2']);
      expect(first.fromCache, isFalse);
      expect(first.tierCalls, 1);
      expect(first.file.existsSync(), isTrue);
      expect(store.usageCountThisMonth(now: DateTime.now()), 1);

      final second = await command.nodes(fileKey: 'K', ids: ['1:2']);
      expect(second.fromCache, isTrue);
      expect(second.tierCalls, 0);
      expect(client.calls.length, 1, reason: '缓存命中不应再打接口');
      expect(store.usageCountThisMonth(now: DateTime.now()), 1, reason: '缓存命中不写日志');
    });

    test('--refresh 删缓存并重新请求（再记一次用量）', () async {
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);
      await command.nodes(fileKey: 'K', ids: ['1:2']);
      final refreshed = await command.nodes(fileKey: 'K', ids: ['1:2'], refresh: true);
      expect(refreshed.fromCache, isFalse);
      expect(client.calls.length, 2);
      expect(store.usageCountThisMonth(now: DateTime.now()), 2);
    });

    test('额度错误：抛 429、不写日志、不留残缺缓存', () async {
      final client = FailingClient(
        FigmaHttpException(
            statusCode: 429,
            url: Uri.parse('https://example'),
            retryAfter: const Duration(seconds: 30)),
      );
      await expectLater(
        FetchCommand(store: store, client: client).nodes(fileKey: 'K', ids: ['1:2']),
        throwsA(isA<FigmaHttpException>().having((e) => e.isRateLimited, 'isRateLimited', isTrue)),
      );
      // 失败不写日志、不留残缺缓存
      expect(store.usageCountThisMonth(now: DateTime.now()), 0);
      expect(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(), isFalse);
    });
  });

  group('init', () {
    test('创建 token 模板、补 gitignore、建缓存目录（幂等）', () {
      final first = InitCommand(store).run();
      expect(first.tokenCreated, isTrue);
      expect(first.gitignoreAdded, containsAll(['.figma-token', '.figma-cache/']));
      expect(store.budgetFile.existsSync(), isTrue);

      final second = InitCommand(store).run();
      expect(second.tokenCreated, isFalse);
      expect(second.gitignoreAdded, isEmpty);
      final gitignore = File('${root.path}/.gitignore').readAsStringSync();
      expect('.figma-token'.allMatches(gitignore).length, 1);
    });
  });

  group('usage', () {
    test('统计本月次数与预算', () {
      store.logUsage(kind: 'nodes', cacheFile: 'a.json');
      store.logUsage(kind: 'images', cacheFile: 'b.json');
      final summary = UsageCommand(store).run();
      expect(summary.used, 2);
      expect(summary.limit, 20);
      expect(summary.remaining, 18);
      expect(summary.recent.length, 2);
      expect(summary.isNearLimit, isFalse);
    });

    test('预算文件可覆盖上限', () {
      store.dir.createSync(recursive: true);
      store.budgetFile.writeAsStringSync(jsonEncode({'limit': 3}));
      store.logUsage(kind: 'nodes', cacheFile: 'a.json');
      store.logUsage(kind: 'nodes', cacheFile: 'b.json');
      store.logUsage(kind: 'nodes', cacheFile: 'c.json');
      final summary = UsageCommand(store).run();
      expect(summary.limit, 3);
      expect(summary.isNearLimit, isTrue);
    });
  });

  group('url', () {
    test('解析 design / file 链接与裸 nodeId', () {
      const command = UrlCommand();
      final design = command.run(
        'https://www.figma.com/design/UpyszH8lFtWYwrIXm1XAWw/app?node-id=1862-9222',
      );
      expect(design.fileKey, 'UpyszH8lFtWYwrIXm1XAWw');
      expect(design.nodeId, '1862:9222');

      final file = command.run('https://www.figma.com/file/ABC/demo?node-id=1-2');
      expect(file.fileKey, 'ABC');
      expect(file.nodeId, '1:2');

      expect(command.run('1862:9222').nodeId, '1862:9222');
      expect(() => command.run('not a url'), throwsFormatException);
    });
  });
}
