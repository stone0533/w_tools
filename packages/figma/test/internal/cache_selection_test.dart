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
    CacheStore.homeOverride = home.path;
    final dir = CacheStore(root).dir..createSync(recursive: true);
    full = File('${dir.path}/nodes-K-1-2.json')
      ..writeAsStringSync(jsonEncode(_cache(withChildren: true)));
    depth = File('${dir.path}/nodes-K-1-2-d2.json')
      ..writeAsStringSync(jsonEncode(_cache(withChildren: false)));
    // 完整缓存更旧，depth 缓存更新；spec / tokens 仍应选完整的那份。
    full.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depth.setLastModifiedSync(DateTime.now());
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  test('同 id 命中完整缓存与 --depth 缓存时优先完整缓存', () {
    final sources = resolveNodeCaches(CacheStore(root), <String>['1:2']);

    expect(sources['1:2']!.path, full.path);
  });

  test('只有 --depth 缓存时仍可用，并能被识别为裁剪源', () {
    full.deleteSync();

    final sources = resolveNodeCaches(CacheStore(root), <String>['1:2']);

    expect(sources['1:2']!.path, depth.path);
    expect(depthLimitedCachePaths(sources.values.map((f) => f.path)), <String>[depth.path]);
  });
}
