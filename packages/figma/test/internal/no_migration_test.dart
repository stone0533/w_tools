import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';

/// 0.14.0 起 CLI 不再自动迁移旧路径；旧文件保持原样。
void main() {
  late Directory root;
  late Directory home;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_no_migrate_');
    home = Directory.systemTemp.createTempSync('figma_no_migrate_home_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  Future<ProcessResult> runInit() {
    return Process.run(
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
  }

  test('CLI 不再搬走旧 .figma-cache / .figma-token', () async {
    final legacy = Directory('${root.path}/.figma-cache')..createSync(recursive: true);
    final legacyCache = File('${legacy.path}/nodes-y.json')..writeAsStringSync('{"nodes":{}}');
    final legacyToken = File('${root.path}/.figma-token')..writeAsStringSync('figd_legacy');

    final result = await runInit();

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(legacyCache.existsSync(), isTrue, reason: '旧缓存保持原样');
    expect(legacyToken.existsSync(), isTrue, reason: '旧 token 保持原样');

    final store = CacheStore(root, home: home.path);
    expect(File('${store.dir.path}/nodes-y.json').existsSync(), isFalse);
    expect(File('${store.dir.path}/_migrated-v1').existsSync(), isFalse);
  });

  test('init 不再改 .gitignore', () async {
    File('${root.path}/.gitignore').writeAsStringSync('build/\n');
    Directory('${root.path}/.figma-cache').createSync();

    final result = await runInit();

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(File('${root.path}/.gitignore').readAsStringSync(), 'build/\n');
  });
}
