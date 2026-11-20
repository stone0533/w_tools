import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cache/nodes_index.dart' show isNodesCacheFile;
import 'package:w_tools_figma/src/cli/cache_handler.dart';

void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cache_');
    home = Directory.systemTemp.createTempSync('figma_cache_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  test('stats 统计当前项目缓存的文件数与字节数', () {
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});
    final stats = cacheStats(store);
    expect(stats.files, 1);
    expect(stats.bytes, greaterThan(0));
    expect(stats.dir.path, store.dir.path);
  });

  test('clean 只删当前项目缓存', () {
    final other = CacheStore(Directory('${root.path}/other'), home: home.path);
    other.write(other.cacheFile(kind: 'nodes', fileKey: 'X', ids: '1:2'), {'a': 1});
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});

    final (dirs, bytes) = cleanCache(store);

    expect(dirs, 1);
    expect(bytes, greaterThan(0));
    expect(store.dir.existsSync(), isFalse);
    expect(other.dir.existsSync(), isTrue, reason: '别动其它项目的缓存');
  });

  test('clean --all 删所有项目缓存，但保留用量/预算', () {
    final other = CacheStore(Directory('${root.path}/other'), home: home.path);
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});
    other.write(other.cacheFile(kind: 'nodes', fileKey: 'X', ids: '1:2'), {'a': 1});
    store.logUsage(kind: 'nodes', cacheFile: 'x.json');

    final (dirs, _) = cleanCache(store, all: true);

    expect(dirs, 2);
    expect(store.dir.existsSync(), isFalse);
    expect(other.dir.existsSync(), isFalse);
    expect(store.usageFile.existsSync(), isTrue, reason: '用量是账号级，不该被清');
  });

  test('没有缓存时 stats 为 0、clean 返回 0 个目录', () {
    expect(cacheStats(store).files, 0);
    expect(cleanCache(store), (0, 0));
  });

  test('cleanFile 只删点名文件，拒绝目录外路径', () {
    final nodes = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
    store.write(nodes, {'a': 1});
    final legacy = File('${store.dir.path}/file-K-d2.json')..writeAsStringSync('{}');

    final (file, bytes) = cleanFile(store, 'nodes-K-1-2.json');

    expect(file.path, nodes.path);
    expect(bytes, greaterThan(0));
    expect(nodes.existsSync(), isFalse);
    expect(legacy.existsSync(), isTrue);
    expect(() => cleanFile(store, '../outside.json'), throwsFormatException);
    expect(() => cleanFile(store, 'sub/nodes.json'), throwsFormatException);
  });

  test('stats --files 区分 legacy / nodes / index', () {
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});
    File('${store.dir.path}/file-K-d2.json').writeAsStringSync('{}');
    File('${store.dir.path}/_nodes-index.json').writeAsStringSync('{}');

    final entries = cacheFileEntries(store);
    final byName = {
      for (final entry in entries) entry.path.split('/').last: entry.kind,
    };
    expect(byName['file-K-d2.json'], 'legacy');
    expect(byName['_nodes-index.json'], 'index');
    expect(byName.values, contains('nodes'));
  });

  test('stats --files 用 _nodes-index 标记 indexed', () {
    final nodes = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
    store.write(nodes, {'a': 1});
    final legacy = File('${store.dir.path}/file-K-d2.json')..writeAsStringSync('{}');
    File('${store.dir.path}/_nodes-index.json').writeAsStringSync(jsonEncode({
      'version': 5,
      'files': <String, Object?>{nodes.path: <String, Object?>{}},
    }));

    final entries = cacheFileEntries(store);
    final byPath = {for (final entry in entries) entry.path: entry};

    expect(byPath[nodes.path]!.indexed, isTrue);
    expect(byPath[legacy.path]!.indexed, isFalse);
    expect(byPath['${store.dir.path}/_nodes-index.json']!.indexed, isFalse);
  });

  test('cleanLegacy 只删 file-*，保留 nodes 与 index', () {
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});
    final legacy = File('${store.dir.path}/file-K-d2.json')..writeAsStringSync('{}');
    final index = File('${store.dir.path}/_nodes-index.json')..writeAsStringSync('{}');

    final (files, bytes) = cleanLegacy(store);

    expect(files, 1);
    expect(bytes, greaterThan(0));
    expect(legacy.existsSync(), isFalse);
    expect(index.existsSync(), isTrue);
    expect(cacheStats(store).files, 2);
  });

  test('Windows：缓存用 LOCALAPPDATA、令牌用 APPDATA', () {
    final win = CacheStore(
      root,
      home: home.path,
      windows: true,
      environment: {
        'LOCALAPPDATA': 'C:/Users/x/AppData/Local',
        'APPDATA': 'C:/Users/x/AppData/Roaming'
      },
    );
    expect(win.cacheRoot.path, contains('AppData/Local'));
    expect(win.tokenFile.path, contains('AppData/Roaming'));
  });

  test('Windows 缺环境变量时回落到 HOME', () {
    final win = CacheStore(root, home: home.path, windows: true, environment: const {});
    expect(win.cacheRoot.path, '${home.path}/.cache/w_tools/figma');
    expect(win.tokenFile.path, '${home.path}/.config/w_tools/figma-token');
  });

  group('isNodesCacheFile', () {
    test('POSIX 与 Windows 路径都能认出 nodes 缓存', () {
      expect(isNodesCacheFile('/tmp/cache/nodes-abc.json'), isTrue);
      expect(
        isNodesCacheFile(r'C:\Users\me\.cache\w_tools\figma\nodes-abc.json'),
        isTrue,
      );
      expect(isNodesCacheFile('/tmp/cache/file-abc.json'), isFalse);
      expect(isNodesCacheFile('/tmp/cache/nodes-abc.txt'), isFalse);
    });
  });
}
