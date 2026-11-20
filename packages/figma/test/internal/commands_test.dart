import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/fetch_handler.dart';
import 'package:w_tools_figma/src/commands/file_meta.dart';
import 'package:w_tools_figma/src/cli/init_handler.dart';
import 'package:w_tools_figma/src/cli/url_handler.dart';
import 'package:w_tools_figma/src/cli/usage_handler.dart';
import 'package:w_tools_figma/src/spec/cache_document.dart';
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

  late Directory home;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_test_');
    home = Directory.systemTemp.createTempSync('figma_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  group('fetch', () {
    test('首次请求写缓存与用量日志，第二次命中缓存不再请求', () async {
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);

      final first = await command.nodes(fileKey: 'K', ids: ['1:2']);
      expect(first.fromCache, isFalse);
      expect(first.tierCalls, 1);
      expect(first.file.existsSync(), isTrue);
      expect(store.usageEntries().length, 1);

      final second = await command.nodes(fileKey: 'K', ids: ['1:2']);
      expect(second.fromCache, isTrue);
      expect(second.tierCalls, 0);
      expect(client.calls.length, 1, reason: '缓存命中不应再打接口');
      expect(store.usageEntries().length, 1, reason: '缓存命中不写日志');
    });

    test('nodes 全 null 不写缓存，仍记一次用量', () async {
      final command = FetchCommand(
        store: store,
        client: FakeClient({
          'nodes': {'1:2': null},
        }),
      );

      await expectLater(
        command.nodes(fileKey: 'K', ids: ['1:2']),
        throwsStateError,
      );
      expect(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(),
        isFalse,
      );
      expect(store.usageEntries().single.cacheFile, '-');
    });

    test('fetchJson 暴露 missingNodeIds', () {
      final result = FetchResult(
        file: File('${store.dir.path}/missing.json'),
        json: const <String, dynamic>{},
        fromCache: false,
        tierCalls: 1,
        missingNodeIds: const <String>['2:3'],
      );

      expect(fetchJson(result)['missingNodeIds'], const <String>['2:3']);
    });

    test('nodes 部分 null 只缓存有效节点并报告缺失', () async {
      final command = FetchCommand(
        store: store,
        client: FakeClient({
          'nodes': {
            '1:2': {
              'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
            },
            '2:3': null,
          },
        }),
      );

      final result = await command.nodes(fileKey: 'K', ids: ['1:2', '2:3']);

      expect(result.missingNodeIds, <String>['2:3']);
      final saved = jsonDecode(result.file.readAsStringSync()) as Map;
      expect((saved['nodes'] as Map).keys, <String>['1:2']);

      final second = await command.nodes(fileKey: 'K', ids: ['1:2', '2:3']);
      expect(second.fromCache, isTrue);
      expect(second.missingNodeIds, <String>['2:3']);
    });

    test('缓存命中时校验 requestedIds，缺的写入 missingNodeIds', () async {
      final target = store.cacheFile(
        kind: 'nodes',
        fileKey: 'K',
        ids: '1:2,2:3',
      );
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': {'id': '1:2', 'type': 'FRAME', 'name': 'OnlyOne'},
          },
        },
      }));
      final client = FakeClient({'nodes': <String, Object?>{}});

      final result =
          await FetchCommand(store: store, client: client).nodes(fileKey: 'K', ids: ['1:2', '2:3']);

      expect(result.fromCache, isTrue);
      expect(result.missingNodeIds, <String>['2:3']);
      expect(client.calls, isEmpty);
    });

    test('拆分 id 命中已有缓存时不再请求', () async {
      final source = store.cacheFile(
        kind: 'nodes',
        fileKey: 'K',
        ids: '1:2,2:3',
      );
      store.write(source, {
        'nodes': {
          '1:2': {
            'document': {'id': '1:2', 'type': 'FRAME', 'name': 'Cached'},
          },
        },
      });
      final client = FakeClient({'nodes': <String, Object?>{}});

      final result =
          await FetchCommand(store: store, client: client).nodes(fileKey: 'K', ids: ['1:2']);

      expect(result.fromCache, isTrue);
      expect(client.calls, isEmpty);
      expect(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(),
        isTrue,
      );
    });

    test('损坏的精确缓存报错，不静默重拉', () async {
      final target = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
      target.parent.createSync(recursive: true);
      target.writeAsStringSync('{bad');
      final client = FakeClient({'nodes': <String, Object?>{}});

      await expectLater(
        FetchCommand(store: store, client: client).nodes(fileKey: 'K', ids: ['1:2']),
        throwsStateError,
      );
      expect(client.calls, isEmpty);
    });

    test('全 null 的 nodes 缓存读成空，不当损坏', () {
      final file = File('${store.dir.path}/nodes-null.json');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('{"nodes":{"1:2":null}}');

      expect(readDocuments(file), isEmpty);
      expect(readDocument(file, '1:2'), isNull);
    });

    test('nodes --depth 会带上 depth 且缓存文件名区分深度', () async {
      // 前面的用例可能已经写入同 id 的缓存；这个用例专门验证请求参数，先清空。
      if (store.dir.existsSync()) {
        for (final entity in store.dir.listSync()) {
          if (entity is File) entity.deleteSync();
        }
      }
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);

      final shallow = await command.nodes(fileKey: 'K', ids: ['1:2'], depth: 1);
      expect(client.calls.single.queryParameters['depth'], '1');
      expect(shallow.file.path, endsWith('-d1.json'));

      final full = await command.nodes(fileKey: 'K', ids: ['1:2']);
      expect(client.calls.last.queryParameters.containsKey('depth'), isFalse,
          reason: '不传 depth 时不应带参数（保持旧行为）');
      expect(full.file.path, isNot(endsWith('-d1.json')));
      expect(full.file.existsSync(), isTrue);
    });

    test('nodes ids 去重排序，缓存 key 与请求顺序无关', () async {
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);

      final first = await command.nodes(
        fileKey: 'K',
        ids: ['2:3', '1:2', '1:2'],
      );
      expect(client.calls.single.queryParameters['ids'], '1:2,2:3');
      expect(first.fromCache, isFalse);

      final second = await command.nodes(fileKey: 'K', ids: ['1:2', '2:3']);
      expect(second.fromCache, isTrue);
      expect(second.file.path, first.file.path);
      expect(client.calls.length, 1, reason: '顺序/重复不应产生第二次请求');
    });

    test('images 不缓存：去重排序请求，直接返回 URL', () async {
      final client = FakeClient({
        'images': {
          '1:2': 'https://cdn.example/1.png',
          '2:3': null,
        },
      });
      final command = FetchCommand(store: store, client: client);

      final first = await command.imageUrls(
        fileKey: 'K',
        ids: ['2:3', '1:2', '1:2'],
      );
      expect(client.calls.single.queryParameters['ids'], '1:2,2:3');
      expect(first['1:2'], 'https://cdn.example/1.png');
      expect(first['2:3'], isNull);
      expect(store.usageEntries().length, 1);
      expect(store.usageEntries().single.cacheFile, 'imageUrls:K');
      expect(
        store.cacheFile(kind: 'images', fileKey: 'K', ids: '1:2,2:3', scale: 2).existsSync(),
        isFalse,
        reason: '图片地址不缓存',
      );

      await command.imageUrls(fileKey: 'K', ids: ['1:2', '2:3']);
      expect(client.calls.length, 2, reason: '没有缓存，每次都要请求');
    });

    test('--refresh 请求失败时保留旧缓存', () async {
      final first = FetchCommand(store: store, client: FakeClient(payload));
      final cached = await first.nodes(fileKey: 'K', ids: ['1:2']);
      final before = cached.file.readAsStringSync();

      final failing = FetchCommand(
        store: store,
        client: FailingClient(StateError('network down')),
      );
      await expectLater(
        failing.nodes(fileKey: 'K', ids: ['1:2'], refresh: true),
        throwsA(isA<StateError>()),
      );
      expect(cached.file.existsSync(), isTrue);
      expect(cached.file.readAsStringSync(), before);
    });

    test('--refresh 跳过缓存并重新请求（再记一次用量）', () async {
      final client = FakeClient(payload);
      final command = FetchCommand(store: store, client: client);
      await command.nodes(fileKey: 'K', ids: ['1:2']);
      final refreshed = await command.nodes(fileKey: 'K', ids: ['1:2'], refresh: true);
      expect(refreshed.fromCache, isFalse);
      expect(client.calls.length, 2);
      expect(store.usageEntries().length, 2);
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
      expect(store.usageEntries().length, 0);
      expect(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(), isFalse);
    });
  });

  test('损坏缓存按未命中处理，不直接抛 FormatException', () {
    final file = File('${store.dir.path}/broken.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('{not json');
    expect(store.read(file), isNull);
  });

  test('readFileMeta 读取 last_touched_at', () async {
    final meta = await readFileMeta(
      FakeClient({
        'file': {
          'version': 'v1',
          'last_touched_at': '2026-11-13T01:03:43.385Z',
        },
      }),
      'K',
    );
    expect(meta?.version, 'v1');
    expect(meta?.lastTouchedAt, '2026-11-13T01:03:43.385Z');
  });

  group('init', () {
    test('创建 token 模板、建缓存目录（幂等）', () {
      final first = initProject(store);
      expect(first.tokenCreated, isTrue);
      expect(store.tokenFile.existsSync(), isTrue);
      expect(store.budgetFile.existsSync(), isTrue);

      final second = initProject(store);
      expect(second.tokenCreated, isFalse);
    });
  });

  group('usage', () {
    test('统计本月次数与预算', () {
      store.logUsage(kind: 'nodes', cacheFile: 'a.json');
      store.logUsage(kind: 'images', cacheFile: 'b.json');
      final summary = usageSummary(store);
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
      final summary = usageSummary(store);
      expect(summary.limit, 3);
      expect(summary.isNearLimit, isTrue);
    });
  });

  group('url', () {
    test('解析 design / file 链接与裸 nodeId', () {
      final design = parseFigmaUrl(
        'https://www.figma.com/design/UpyszH8lFtWYwrIXm1XAWw/app?node-id=1862-9222',
      );
      expect(design.fileKey, 'UpyszH8lFtWYwrIXm1XAWw');
      expect(design.nodeId, '1862:9222');

      final file = parseFigmaUrl('https://www.figma.com/file/ABC/demo?node-id=1-2');
      expect(file.fileKey, 'ABC');
      expect(file.nodeId, '1:2');

      expect(() => parseFigmaUrl('1862:9222'), throwsFormatException);
      expect(() => parseFigmaUrl('https://example.com/a:b'), throwsFormatException);
      expect(() => parseFigmaUrl('C:/tmp/x'), throwsFormatException);
      expect(() => parseFigmaUrl('not a url'), throwsFormatException);
    });
  });
}
