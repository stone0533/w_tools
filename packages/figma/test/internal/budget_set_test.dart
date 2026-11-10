import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/budget_handler.dart';

void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_budget_set_');
    home = Directory.systemTemp.createTempSync('figma_budget_set_home_');
    CacheStore.homeOverride = home.path;
    store = CacheStore(root);
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    exitCode = 0;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  Map<String, dynamic> readBudget() =>
      jsonDecode(store.budgetFile.readAsStringSync()) as Map<String, dynamic>;

  test('budget --set 只改 limit，保住存量字段', () {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync(jsonEncode({'month': '2026-11', 'limit': 20, 'used': 3}));

    runBudget(['--set=5', '--root=${root.path}']);

    final payload = readBudget();
    expect(payload['limit'], 5);
    expect(payload['month'], '2026-11', reason: '覆盖式写盘会丢掉 month');
    expect(payload['used'], 3, reason: '覆盖式写盘会丢掉 used');
  });

  test('预算文件不存在时写 {"limit"}，不抛错', () {
    runBudget(['--set=7', '--root=${root.path}']);

    expect(readBudget(), {'limit': 7});
    expect(exitCode, 0);
  });

  test('预算文件损坏时不崩，写成 {"limit"}', () {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync('{bad');

    runBudget(['--set=9', '--root=${root.path}']);

    expect(readBudget(), {'limit': 9});
    expect(exitCode, 0);
  });
}
