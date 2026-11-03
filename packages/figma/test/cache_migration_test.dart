import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';

/// 旧路径（`<project>/.figma-cache`、`<project>/.figma-token`）的迁移行为。
void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_mig_');
    home = Directory.systemTemp.createTempSync('figma_mig_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  test('缓存搬进项目目录；用量并入账号级；预算按账号级补齐', () {
    final legacy = Directory('${root.path}/.figma-cache')..createSync();
    File('${legacy.path}/nodes-K-1.json').writeAsStringSync('{"nodes":{}}');
    File('${legacy.path}/_usage.log').writeAsStringSync(
      '2026-11-02T10:00:00\tnodes\tnodes-K-1.json\n',
    );
    File('${legacy.path}/_budget.json').writeAsStringSync('{"limit":5}');

    final notes = store.migrateLegacy();

    expect(File('${store.dir.path}/nodes-K-1.json').existsSync(), isTrue);
    expect(File('${store.dir.path}/_usage.log').existsSync(), isFalse, reason: '不应留在项目目录');
    expect(store.usageCountThisMonth(now: DateTime(2026, 11, 3)), 1);
    expect(store.budgetLimit(), 5);
    expect(legacy.existsSync(), isFalse);
    expect(notes.any((n) => n.contains('用量')), isTrue);
  });

  test('账号级已有用量时是追加而不是覆盖', () {
    store.cacheRoot.createSync(recursive: true);
    store.usageFile.writeAsStringSync('2026-11-01T09:00:00\tnodes\ta.json\n');
    final legacy = Directory('${root.path}/.figma-cache')..createSync();
    File('${legacy.path}/_usage.log').writeAsStringSync('2026-11-02T09:00:00\tnodes\tb.json\n');

    store.migrateLegacy();

    expect(store.usageCountThisMonth(now: DateTime(2026, 11, 3)), 2);
  });

  test('新位置是模板、旧位置是真 token → 用真 token 覆盖', () {
    store.tokenFile.parent.createSync(recursive: true);
    store.tokenFile.writeAsStringSync('figd_REPLACE_ME\n');
    store.legacyTokenFile.writeAsStringSync('figd_real\n');

    store.migrateLegacy();

    expect(store.tokenFile.readAsStringSync(), contains('figd_real'));
    expect(store.legacyTokenFile.existsSync(), isFalse, reason: '旧文件应删除');
  });

  test('旧位置是模板、新位置是真 token → 删模板、保留真 token', () {
    store.tokenFile.parent.createSync(recursive: true);
    store.tokenFile.writeAsStringSync('figd_real\n');
    store.legacyTokenFile.writeAsStringSync('figd_REPLACE_ME\n');

    store.migrateLegacy();

    expect(store.tokenFile.readAsStringSync(), contains('figd_real'));
    expect(store.legacyTokenFile.existsSync(), isFalse);
  });

  test('两边都是真 token 时不动旧文件，只提示', () {
    store.tokenFile.parent.createSync(recursive: true);
    store.tokenFile.writeAsStringSync('figd_new\n');
    store.legacyTokenFile.writeAsStringSync('figd_old\n');

    final notes = store.migrateLegacy();

    expect(store.tokenFile.readAsStringSync(), contains('figd_new'));
    expect(store.legacyTokenFile.existsSync(), isTrue);
    expect(notes.any((n) => n.contains('保留未动')), isTrue);
  });

  test('projectId 稳定且带目录名', () {
    expect(store.projectId, startsWith('figma_mig_'));
    expect(store.projectId, CacheStore(root, home: home.path).projectId);
  });

  test('无旧文件时不产生迁移说明', () {
    expect(store.migrateLegacy(), isEmpty);
  });
}
