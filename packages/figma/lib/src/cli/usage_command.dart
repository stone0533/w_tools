import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/usage_command.dart';
import 'args.dart';
import 'cli_io.dart';

void runUsage(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json'});
  final store = CacheStore(Directory(options.root));
  final summary = UsageCommand(store).run();
  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.usage/1',
      'month': summary.month,
      'used': summary.used,
      'limit': summary.limit,
      'remaining': summary.remaining,
      'recent': [
        for (final e in summary.recent) {'at': e.at, 'kind': e.kind, 'cache': e.cacheFile},
      ],
    }));
    return;
  }
  printLine('Tier 1 calls this month (${summary.month}): ${summary.used} / ${summary.limit}');
  if (summary.isNearLimit) {
    printLine('⚠️ 已用 ${summary.used}/${summary.limit}，本月剩余 ${summary.remaining} 次');
  }
  if (summary.recent.isEmpty) {
    printLine('（本月还没有调用记录）');
  } else {
    printLine('最近 ${summary.recent.length} 条：');
    for (final e in summary.recent) {
      printLine('  ${e.at}  ${e.kind}  ${e.cacheFile}');
    }
  }
}

void runBudget(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json', 'set'});
  final store = CacheStore(Directory(options.root));
  if (options.budgetSet != null) {
    store.dir.createSync(recursive: true);
    store.budgetFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'limit': options.budgetSet}),
    );
    printLine('月度预算已设为 ${options.budgetSet}');
    return;
  }
  final summary = UsageCommand(store).run();
  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.budget/1',
      'limit': summary.limit,
      'used': summary.used,
      'remaining': summary.remaining,
    }));
    return;
  }
  printLine('月度预算 ${summary.limit} 次，本月已用 ${summary.used} 次，剩余 ${summary.remaining} 次');
}
