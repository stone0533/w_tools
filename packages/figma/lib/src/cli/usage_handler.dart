import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../commands/usage_command.dart';
import 'args.dart';
import 'cli_io.dart';

void runUsage(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json'});
  rejectExtraPositional(options, 0);

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
