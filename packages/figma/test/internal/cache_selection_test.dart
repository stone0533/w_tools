import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cache/nodes_index.dart';

Map<String, Object?> _cache({required bool withChildren}) => {
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Demo',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
            'children': withChildren
                ? [
                    {
                      'id': '1:3',
                      'type': 'TEXT',
                      'name': 'Title',
                      'characters': 'Hello',
                      'absoluteBoundingBox': {'x': 10, 'y': 10, 'width': 80, 'height': 20},
                    },
                  ]
                : <Object?>[],
          },
        },
      },
    };

void main() {
  late Directory root;
  late Directory home;
  late File full;
  late File depth;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cache_select_');
    home = Directory.systemTemp.createTempSync('figma_cache_select_home_');
    final dir = CacheStore(root, home: home.path).dir..createSync(recursive: true);
    full = File('${dir.path}/nodes-K-1-2.json')
      ..writeAsStringSync(jsonEncode(_cache(withChildren: true)));
    depth = File('${dir.path}/nodes-K-1-2-d2.json')
      ..writeAsStringSync(jsonEncode(_cache(withChildren: false)));
    // resolveNodeCaches 默认（preferFullDepth=false）取最新；CLI 的 spec / tokens 默认传 true。
    full.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depth.setLastModifiedSync(DateTime.now());
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  test('同 id 命中完整缓存与更新的 --depth 缓存时取最新', () {
    final sources = resolveNodeCaches(CacheStore(root, home: home.path), <String>['1:2']);

    expect(sources['1:2']!.path, depth.path);
  });

  test('preferFullDepth: true 时优先完整缓存', () {
    final sources = resolveNodeCaches(
      CacheStore(root, home: home.path),
      <String>['1:2'],
      preferFullDepth: true,
    );

    expect(sources['1:2']!.path, full.path);
  });

  test('cacheFileKey 只从 nodes-<fileKey>- 前缀解析', () {
    expect(cacheFileKey('/c/nodes-ABC-1-2.json'), 'ABC');
    expect(cacheFileKey('/c/nodes-FILEA-10-1-d2.json'), 'FILEA');
    expect(cacheFileKey('/c/nodes-page.json'), isNull);
    expect(cacheFileKey('/c/_nodes-index.json'), isNull);
  });

  test('提示能列出包含目标的完整缓存，并带上完整路径', () {
    final store = CacheStore(root, home: home.path);
    expect(fullNodesCachePaths(store, <String>['1:2']), <String>[full.path]);
    final message = depthLimitedMessage(<String>[depth.path], fullPaths: <String>[full.path]);
    expect(message, contains(depth.path));
    expect(message, contains(full.path));
    expect(message, contains('--file='));
  });

  test('只有 --depth 缓存时仍可用，并能被识别为裁剪源', () {
    full.deleteSync();

    final sources = resolveNodeCaches(CacheStore(root, home: home.path), <String>['1:2']);

    expect(sources['1:2']!.path, depth.path);
    expect(depthLimitedCachePaths(sources.values.map((f) => f.path)), <String>[depth.path]);
  });

  test('spec / tokens 读缓存不写 _nodes-index.json', () {
    final store = CacheStore(root, home: home.path);
    resolveNodeCaches(store, <String>['1:2']);

    expect(File('${store.dir.path}/_nodes-index.json').existsSync(), isFalse);
  });
}
