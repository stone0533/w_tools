import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';

/// 按 URL 路由的 fake：`/meta` 返回版本，`/nodes` 返回节点树。
class _RoutedClient implements FigmaClient {
  _RoutedClient({required this.version});

  String version;
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    if (url.path.endsWith('/meta')) {
      return {
        'file': {'version': version, 'lastTouchedAt': '2026-11-02T00:00:00Z'},
      };
    }
    return {
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    };
  }

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
    root = Directory.systemTemp.createTempSync('figma_stale_');
    store = CacheStore(root);
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), payload);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('未开 checkStale 时不发 meta 请求', () async {
    final client = _RoutedClient(version: 'v2');
    final result = await FetchCommand(store: store, client: client).nodes(
      fileKey: 'K',
      ids: const ['1:2'],
    );
    expect(result.fromCache, isTrue);
    expect(client.calls, isEmpty, reason: '默认不额外打接口');
    expect(result.stale, isFalse);
  });

  test('首次 checkStale 只记录版本，不报过期', () async {
    final client = _RoutedClient(version: 'v1');
    final result = await FetchCommand(store: store, client: client).nodes(
      fileKey: 'K',
      ids: const ['1:2'],
      checkStale: true,
    );
    expect(result.fromCache, isTrue);
    expect(result.stale, isFalse);
    expect(client.calls.single.path, endsWith('/meta'));
    expect(store.metaFile('K').existsSync(), isTrue);
  });

  test('版本变化时报 stale，且不自动重拉（不消耗 Tier 1）', () async {
    final first = _RoutedClient(version: 'v1');
    await FetchCommand(store: store, client: first).nodes(
      fileKey: 'K',
      ids: const ['1:2'],
      checkStale: true,
    );

    final second = _RoutedClient(version: 'v2');
    final result = await FetchCommand(store: store, client: second).nodes(
      fileKey: 'K',
      ids: const ['1:2'],
      checkStale: true,
    );
    expect(result.stale, isTrue);
    expect(result.cachedVersion, 'v1');
    expect(result.latestVersion, 'v2');
    expect(result.tierCalls, 0, reason: '只提示，不自动重拉');
    expect(store.usageCountThisMonth(now: DateTime.now()), 0);
  });
}
