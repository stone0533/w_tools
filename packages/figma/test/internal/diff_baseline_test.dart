import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cache/nodes_index.dart';
import 'package:w_tools_figma/src/cli/diff_handler.dart';
import 'package:w_tools_figma/src/client/figma_client.dart';
import 'package:w_tools_figma/src/commands/diff_command.dart';

/// 按 URL 路由：`/meta` 给版本，其它（`/nodes`）给节点树。
class _RoutedClient implements FigmaClient {
  _RoutedClient({required this.version, required this.width});

  final String version;
  final double width;
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    if (url.path.endsWith('/meta')) {
      return {
        'file': {'version': version},
      };
    }
    return _nodesPayload(width);
  }

  @override
  void close() {}
}

Map<String, dynamic> _nodesPayload(double width) => {
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Demo',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': width, 'height': 100},
            'children': <Object?>[],
          },
        },
      },
    };

void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_diff_');
    home = Directory.systemTemp.createTempSync('figma_diff_home_');
    CacheStore.homeOverride = home.path;
    store = CacheStore(root);
    store.dir.createSync(recursive: true);
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    // runDiff 会写全局 exitCode；不还原会让整个测试进程非 0 退出。
    exitCode = 0;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  File writeNodesCache(File file, {required double width}) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(_nodesPayload(width)));
    return file;
  }

  group('findNodesCache', () {
    test('优先返回没被 --depth 裁剪的缓存', () {
      final full = writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'),
        width: 10,
      );
      final depth = writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2', depth: 2),
        width: 10,
      );
      // 让 depth 缓存更新，确认优先级不是只按 mtime。
      full.setLastModifiedSync(DateTime(2020));
      depth.setLastModifiedSync(DateTime(2026));

      expect(findNodesCache(store, '1:2')!.path, full.path);
      expect(findNodesCache(store, '1:2', preferFullDepth: false)!.path, depth.path);
    });

    test('没有缓存时返回 null，不抛错', () {
      expect(findNodesCache(store, '1:2'), isNull);
    });

    test('nodesCacheDepth 只认文件名末尾的 -d<n>', () {
      expect(nodesCacheDepth('nodes-K-1-2-d2.json'), 2);
      expect(nodesCacheDepth('nodes-K-d2-1-2.json'), isNull);
      expect(nodesCacheDepth(r'C:\cache\nodes-K-1-2-d3.json'), 3);
    });
  });

  group('DiffCommand 用调用方给的基线', () {
    test('depth 缓存当基线时能比出变化（不再误报没有变化）', () async {
      final depth = writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2', depth: 2),
        width: 10,
      );
      final client = _RoutedClient(version: 'v2', width: 20);

      final result = await DiffCommand(store: store, client: client)
          .run(fileKey: 'K', nodeId: '1:2', oldFile: depth);

      expect(result.tierCalls, 1);
      expect(result.changes, isNotEmpty);
      expect(result.changes.map((c) => c.field), contains('size'));
      expect(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(),
        isTrue,
        reason: '新结果仍写规范键',
      );
      expect(File('${depth.path}.prev').existsSync(), isFalse, reason: '基线不是目标文件时不该再快照一份');
    });

    test('基线就是目标文件时先快照，再写新内容', () async {
      final canonical = writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'),
        width: 10,
      );
      final client = _RoutedClient(version: 'v2', width: 30);

      final result = await DiffCommand(store: store, client: client)
          .run(fileKey: 'K', nodeId: '1:2', oldFile: canonical);

      expect(result.changes, isNotEmpty, reason: '不快照就会拿新内容当旧内容，比较结果为空');
      expect(File('${canonical.path}.prev').existsSync(), isFalse, reason: '.prev 要清掉');
      final fresh = readWidth(canonical);
      expect(fresh, 30);
    });

    test('没有基线时仍拉取并写入基线，结果为空但不报错', () async {
      final client = _RoutedClient(version: 'v1', width: 10);

      final result =
          await DiffCommand(store: store, client: client).run(fileKey: 'K', nodeId: '1:2');

      expect(result.isEmpty, isTrue);
      expect(result.tierCalls, 1);
      expect(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(), isTrue);
    });
  });

  group('diff 提示与 --if-stale 判定', () {
    test('没有基线时提示首次 diff，并带上目标路径', () {
      final target = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
      final notes = diffBaselineNotes(baseline: null, targetPath: target.path);
      expect(notes, hasLength(1));
      expect(notes.single, contains('首次 diff'));
      expect(notes.single, contains(target.path));
    });

    test('depth 基线给警告，完整基线不给', () {
      final depth = File('${store.dir.path}/nodes-K-1-2-d2.json');
      expect(diffBaselineNotes(baseline: depth, targetPath: 'x').single, contains('--depth=2'));
      final full = File('${store.dir.path}/nodes-K-1-2.json');
      expect(diffBaselineNotes(baseline: full, targetPath: 'x'), isEmpty);
    });

    test('只有基线 / meta / 版本都在且相等时才跳过', () {
      final baseline = File('${store.dir.path}/nodes-K-1-2.json');
      const meta = <String, dynamic>{'version': 'v1'};
      expect(
        staleVersionUnchanged(baseline: baseline, meta: meta, latest: 'v1'),
        isTrue,
      );
      expect(staleVersionUnchanged(baseline: null, meta: meta, latest: 'v1'), isFalse);
      expect(staleVersionUnchanged(baseline: baseline, meta: null, latest: 'v1'), isFalse);
      expect(staleVersionUnchanged(baseline: baseline, meta: meta, latest: null), isFalse);
      expect(
        staleVersionUnchanged(baseline: baseline, meta: meta, latest: 'v2'),
        isFalse,
      );
      expect(
        staleVersionUnchanged(baseline: baseline, meta: const {}, latest: 'v1'),
        isFalse,
        reason: 'meta 里没有 version 时不能当“没变”',
      );
    });
  });

  group('runDiff 接线', () {
    test('--if-stale + depth 基线 + 版本没变：不发 /nodes', () async {
      writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2', depth: 2),
        width: 10,
      );
      store.write(store.metaFile('K'), <String, dynamic>{'version': 'v1'});
      final client = _RoutedClient(version: 'v1', width: 10);

      await runDiff(
        ['K', '1:2', '--root=${root.path}', '--if-stale', '--json'],
        clientFactory: (_) => client,
      );

      expect(exitCode, 0);
      expect(client.calls, hasLength(1));
      expect(client.calls.single.path, endsWith('/meta'));
    });

    test('没有基线时照常拉取并写基线', () async {
      final client = _RoutedClient(version: 'v1', width: 10);

      await runDiff(
        ['K', '1:2', '--root=${root.path}', '--json'],
        clientFactory: (_) => client,
      );

      expect(exitCode, 0);
      expect(client.calls.map((u) => u.path).any((p) => p.contains('/nodes')), isTrue);
      expect(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2').existsSync(), isTrue);
    });
  });

  group('executeDiff', () {
    test('把解析出的 depth 基线传给比较（不是空基线）', () async {
      writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2', depth: 2),
        width: 10,
      );
      final client = _RoutedClient(version: 'v2', width: 20);

      final outcome = await executeDiff(store: store, client: client, fileKey: 'K', nodeId: '1:2');

      expect(outcome.result, isNotNull);
      expect(outcome.result!.changes, isNotEmpty, reason: '这里传 null 当基线就会只写基线、错报"没有变化"');
      expect(outcome.notes.single, contains('--depth=2'));
    });

    test('--if-stale 版本没变时返回 null 结果，不消耗 Tier 1', () async {
      writeNodesCache(
        store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2', depth: 2),
        width: 10,
      );
      store.write(store.metaFile('K'), <String, dynamic>{'version': 'v1'});
      final client = _RoutedClient(version: 'v1', width: 10);

      final outcome = await executeDiff(
        store: store,
        client: client,
        fileKey: 'K',
        nodeId: '1:2',
        ifStale: true,
      );

      expect(outcome.result, isNull);
      expect(outcome.latestVersion, 'v1');
      expect(outcome.notes, isEmpty);
      expect(client.calls.single.path, endsWith('/meta'));
    });
  });
}

/// 读回缓存里 1:2 的宽度，用来证明写进去的是新数据。
double readWidth(File file) {
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final nodes = raw['nodes'] as Map<String, dynamic>;
  final doc = (nodes['1:2'] as Map<String, dynamic>)['document'] as Map<String, dynamic>;
  final bbox = doc['absoluteBoundingBox'] as Map<String, dynamic>;
  return (bbox['width'] as num).toDouble();
}
