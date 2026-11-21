import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_paths.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';

void main() {
  late Directory base;
  late Directory root;
  late Directory home;

  setUp(() {
    base = Directory.systemTemp.createTempSync('figma_paths_');
    root = Directory('${base.path}/proj')..createSync();
    home = Directory('${base.path}/home')..createSync();
  });

  tearDown(() {
    if (base.existsSync()) base.deleteSync(recursive: true);
  });

  test('同一目录的 . / ./ / .. / 尾斜杠写法得到同一 projectId', () {
    final id = CacheStore(root, home: home.path).projectId;
    expect(CacheStore(Directory('${root.path}/.'), home: home.path).projectId, id);
    expect(CacheStore(Directory('${root.path}/./'), home: home.path).projectId, id);
    expect(CacheStore(Directory('${root.path}/'), home: home.path).projectId, id);
    expect(
      CacheStore(Directory('${root.path}/../proj'), home: home.path).projectId,
      id,
    );
    expect(CacheStore(Directory('${root.path}/sub/..'), home: home.path).projectId, id);
  });

  test('软链目录解析到同一 projectId', () {
    if (Platform.isWindows) return;
    final link = Link('${base.path}/link')..createSync(root.path);
    expect(CacheStore(Directory(link.path), home: home.path).projectId,
        CacheStore(root, home: home.path).projectId);
  });

  test('缓存路径用规范 root，cache stats / clean 输出一致', () {
    final store = CacheStore(Directory('${root.path}/.'), home: home.path);
    expect(
      store.projectId,
      CacheStore(root, home: home.path).projectId,
    );
    expect(store.dir.path, startsWith(CachePaths.canonicalDirectory(home).path));
  });
}
