import '../commands/usage_command.dart';
import 'cache_store.dart';

/// 额度已用尽（本地预算护栏拦截，不是 Figma 返回的 429）。
class BudgetExceededException implements Exception {
  BudgetExceededException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

/// Tier 1 额度护栏：真正发请求前检查本月用量。
///
/// 规则（`docs/figma-cli.md` §2.4）：达到月度上限时默认拒绝，
/// `--ignore-budget` 放行；80% 时由 `usage` / `budget` 打警告。
/// 缓存命中、`spec` / `tokens`（纯本地）不走这里。
class BudgetGuard {
  const BudgetGuard(this.store, {this.softRatio = 0.8});

  final CacheStore store;
  final double softRatio;

  /// 返回非空表示应当拒绝。
  String? denyReason({DateTime? now, bool ignoreBudget = false}) {
    final summary = UsageCommand(store).run(now: now, recent: 0);
    if (summary.used < summary.limit) return null;
    if (ignoreBudget) return null;
    return '本月 Tier 1 额度已用尽（${summary.used}/${summary.limit}）：'
        '加 --ignore-budget 继续，或用 `figma budget --set=<n>` 调整上限';
  }

  /// 是否接近上限（CLI 在成功请求后打警告用）。
  bool isNearLimit({DateTime? now}) =>
      UsageCommand(store).run(now: now, recent: 0).isNearLimit;

  /// 请求前调用：额度已尽且没放行时抛 [BudgetExceededException]。
  void ensureAllowed({DateTime? now, bool ignoreBudget = false}) {
    final reason = denyReason(now: now, ignoreBudget: ignoreBudget);
    if (reason != null) throw BudgetExceededException(reason);
  }
}
