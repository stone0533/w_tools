import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/usage_handler.dart';

void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_usage_set_');
    home = Directory.systemTemp.createTempSync('figma_usage_set_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    exitCode = 0;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  Map<String, dynamic> readBudget() =>
      jsonDecode(store.budgetFile.readAsStringSync()) as Map<String, dynamic>;

  test('usage --set 只改 limit，保住存量字段', () {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync(jsonEncode({'month': '2026-11', 'limit': 20, 'used': 3}));

    runUsage(['--set=5'], store: store);

    final payload = readBudget();
    expect(payload['limit'], 5);
    expect(payload['month'], '2026-11', reason: '覆盖式写盘会丢掉 month');
    expect(payload['used'], 3, reason: '覆盖式写盘会丢掉 used');
  });

  test('预算文件不存在时写 {"limit"}，不抛错', () {
    runUsage(['--set=7'], store: store);

    expect(readBudget(), {'limit': 7});
    expect(exitCode, 0);
  });

  test('limit=1 且 0 次调用时不报接近上限', () {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync(jsonEncode({'limit': 1}));
    final summary = usageSummary(store);
    expect(summary.used, 0);
    expect(summary.isNearLimit, isFalse);
  });

  test('预算文件损坏时不崩，写成 {"limit"}', () {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync('{bad');

    runUsage(['--set=9'], store: store);

    expect(readBudget(), {'limit': 9});
    expect(exitCode, 0);
  });
}
