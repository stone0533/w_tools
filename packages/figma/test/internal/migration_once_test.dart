import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/migration.dart';

/// 旧路径迁移的收口：每个项目只迁一次，但不该漏迁。
void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_migrate_once_');
    home = Directory.systemTemp.createTempSync('figma_migrate_once_home_');
    CacheStore.homeOverride = home.path;
    store = CacheStore(root);
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    exitCode = 0;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  test('同一个项目只迁一次，marker 之后不再重复搬 / 重复刷 note', () {
    final legacy = Directory('${root.path}/.figma-cache')..createSync(recursive: true);
    File('${legacy.path}/nodes-x.json').writeAsStringSync('{"nodes":{}}');

    final first = ensureLegacyMigrated(store);

    expect(first, isNotEmpty);
    expect(File('${store.dir.path}/nodes-x.json').existsSync(), isTrue);
    expect(migratedMarker(store).existsSync(), isTrue);

    // marker 生效后，即使项目里又冒出一条旧用量记录，也不再迁（否则每条命令都刷同一行 note）。
    Directory('${root.path}/.figma-cache').createSync(recursive: true);
    File('${root.path}/.figma-cache/_usage.log')
        .writeAsStringSync('2026-11-10T00:00:00.000\tfile\ta.json\n');

    final second = ensureLegacyMigrated(store);

    expect(second, isEmpty);
    expect(store.usageEntries(), isEmpty);
  });

  test('没有旧路径时不写 marker（老项目以后拷进来仍能迁）', () {
    expect(ensureLegacyMigrated(store), isEmpty);
    expect(migratedMarker(store).existsSync(), isFalse);
  });

  test('走 CLI 的 init 仍然会迁移旧缓存（重复调用删掉后没漏）', () async {
    final legacy = Directory('${root.path}/.figma-cache')..createSync(recursive: true);
    File('${legacy.path}/nodes-y.json').writeAsStringSync('{"nodes":{}}');

    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'bin/figma.dart', 'init', '--root=${root.path}'],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'HOME': home.path,
        'USERPROFILE': home.path,
        'FIGMA_TOKEN': '',
      },
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(File('${store.dir.path}/nodes-y.json').existsSync(), isTrue);
    expect(migratedMarker(store).existsSync(), isTrue);
  });
}
