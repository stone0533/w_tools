import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/budget_guard.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/client/figma_client.dart';
import 'package:w_tools_figma/src/commands/fetch_command.dart';

class _FakeClient implements FigmaClient {
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    return <String, dynamic>{
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    };
  }

  @override
  void close() {}
}

void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_budget_');
    home = Directory.systemTemp.createTempSync('figma_budget_home_');
    store = CacheStore(root, home: home.path);
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync('{"limit": 2}');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  test('未到上限时不拦截', () {
    store.budgetFile.writeAsStringSync('{"limit": 10}');
    store.logUsage(kind: 'file', cacheFile: 'a');
    expect(BudgetGuard(store).denyReason(), isNull);
    expect(BudgetGuard(store).isNearLimit(), isFalse);
  });

  test('到上限时拦截，--ignore-budget 放行', () {
    store.logUsage(kind: 'file', cacheFile: 'a');
    store.logUsage(kind: 'file', cacheFile: 'b');
    final guard = BudgetGuard(store);
    expect(guard.denyReason(), contains('额度已用尽'));
    expect(guard.denyReason(ignoreBudget: true), isNull);
  });

  test('80% 时 isNearLimit 为真', () {
    store.budgetFile.writeAsStringSync('{"limit": 10}');
    for (var i = 0; i < 8; i++) {
      store.logUsage(kind: 'file', cacheFile: 'f$i');
    }
    expect(BudgetGuard(store).isNearLimit(), isTrue);
    expect(BudgetGuard(store).denyReason(), isNull);
  });

  test('fetch 在额度用尽时抛 BudgetExceededException，不消耗请求', () async {
    store.logUsage(kind: 'file', cacheFile: 'a');
    store.logUsage(kind: 'file', cacheFile: 'b');
    final client = _FakeClient();
    final command = FetchCommand(store: store, client: client);

    await expectLater(
      command.nodes(fileKey: 'KEY', ids: const ['1:2'], refresh: true),
      throwsA(isA<BudgetExceededException>()),
    );
    expect(client.calls, isEmpty);
  });

  test('fetch 带 ignoreBudget 时照常请求', () async {
    store.logUsage(kind: 'file', cacheFile: 'a');
    store.logUsage(kind: 'file', cacheFile: 'b');
    final client = _FakeClient();
    final command = FetchCommand(store: store, client: client, ignoreBudget: true);

    final result = await command.nodes(fileKey: 'KEY', ids: const ['1:2'], refresh: true);
    expect(result.fromCache, isFalse);
    expect(client.calls, hasLength(1));
  });
}
