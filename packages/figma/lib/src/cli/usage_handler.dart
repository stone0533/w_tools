import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'args.dart';
import 'cli_io.dart';

void runUsage(List<String> args, {CacheStore? store}) {
  final options = parseCommand(args, 'usage');
  rejectExtra(options, 0);

  final cacheStore = store ?? CacheStore(Directory(options.root));
  if (options.budgetSet != null) {
    cacheStore.budgetFile.parent.createSync(recursive: true);
    // 读-改-写：只覆盖 limit，保住其它字段（存量 month / used 或用户手写的键）。
    final existing = cacheStore.read(cacheStore.budgetFile) ?? <String, dynamic>{};
    final payload = <String, dynamic>{...existing, 'limit': options.budgetSet};
    cacheStore.budgetFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));
    if (!options.json) {
      printLine('月度预算已设为 ${options.budgetSet}');
      return;
    }
  }

  final summary = usageSummary(cacheStore);
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

typedef UsageSummary = ({
  String month,
  int used,
  int limit,
  List<UsageEntry> recent,
  int remaining,
  bool isNearLimit,
});

/// 本月调用次数 / 上限 / 最近记录（纯本地，不发请求）。
UsageSummary usageSummary(CacheStore store, {DateTime? now, int recent = 5}) {
  final at = now ?? DateTime.now();
  final month = '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';
  final entries = store.usageEntries().where((e) => e.at.startsWith(month)).toList();
  final limit = store.budgetLimit();
  final used = entries.length;
  return (
    month: month,
    used: used,
    limit: limit,
    recent: entries.reversed.take(recent).toList(),
    remaining: limit - used,
    isNearLimit: used >= (limit * 0.8).floor(),
  );
}
