import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/commands/cache_command.dart';

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
    final stats = CacheCommand(store).stats();
    expect(stats.files, 1);
    expect(stats.bytes, greaterThan(0));
    expect(stats.dir.path, store.dir.path);
  });

  test('clean 只删当前项目缓存', () {
    final other = CacheStore(Directory('${root.path}/other'), home: home.path);
    other.write(other.cacheFile(kind: 'nodes', fileKey: 'X', ids: '1:2'), {'a': 1});
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), {'a': 1});

    final (dirs, bytes) = CacheCommand(store).clean();

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

    final (dirs, _) = CacheCommand(store).clean(all: true);

    expect(dirs, 2);
    expect(store.dir.existsSync(), isFalse);
    expect(other.dir.existsSync(), isFalse);
    expect(store.usageFile.existsSync(), isTrue, reason: '用量是账号级，不该被清');
  });

  test('没有缓存时 stats 为 0、clean 返回 0 个目录', () {
    expect(CacheCommand(store).stats().files, 0);
    expect(CacheCommand(store).clean(), (0, 0));
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
}
