import '../cache/cache_store.dart';

/// 用量摘要。
class UsageResult {
  UsageResult({
    required this.month,
    required this.used,
    required this.limit,
    required this.recent,
  });

  final String month;
  final int used;
  final int limit;
  final List<UsageEntry> recent;

  int get remaining => limit - used;
  bool get isNearLimit => used >= (limit * 0.8).floor();
}

/// 用量摘要的旧名字（改名过渡用）。
///
/// remove-in: 0.13.0
@Deprecated('Use UsageResult instead')
typedef UsageSummary = UsageResult;

/// `usage`：本月调用次数 / 上限 / 最近记录（纯本地，不发请求）。
class UsageCommand {
  UsageCommand(this.store);

  final CacheStore store;

  UsageResult run({DateTime? now, int recent = 5}) {
    final at = now ?? DateTime.now();
    final month = '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';
    final entries = store.usageEntries().where((e) => e.at.startsWith(month)).toList();
    return UsageResult(
      month: month,
      used: entries.length,
      limit: store.budgetLimit(),
      recent: entries.reversed.take(recent).toList(),
    );
  }
}
