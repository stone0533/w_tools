import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

/// 公开 Issue 的每日预算，存在项目根的 `.w_tools/feedback_budget.json`。
///
/// CLI 没有「会话」概念（每次 `dart run` 都是一个新进程），所以把
/// 「一次会话最多 3–5 条」落成**每个项目每天最多 N 条公开 Issue**。
/// 本地台账不占额度：它可 review、可回滚，也不会给维护者制造通知噪音。
///
/// 文件删了就是 0（`.w_tools/` 的约定是「删了能重建」）；跨天自动归零。
class FeedbackBudget {
  const FeedbackBudget(this.file, {this.now});

  /// 预算文件；默认 `<项目根>/.w_tools/feedback_budget.json`。
  final File file;

  /// 只给测试固定「今天」。生产传 null，用本地时间。
  final DateTime? now;

  static File fileFor(Directory projectRoot) =>
      File(p.join(projectRoot.path, '.w_tools', 'feedback_budget.json'));

  DateTime get _today => now ?? DateTime.now();

  /// 今天对应的日期（YYYY-MM-DD）。
  String get date => _day(_today);

  /// 今天已经用了多少条（日期不同 / 文件损坏都按 0 算）。
  int usedToday() {
    final state = _read();
    if (state == null) return 0;
    return state.date == _day(_today) ? state.count : 0;
  }

  /// 剩余条数；[max] <= 0 表示不限，返回 null。
  int? remainingFor(int max) {
    if (max <= 0) return null;
    return math.max(0, max - usedToday());
  }

  /// 给 `feedback status --json` / 错误提示使用的结构化预算。
  Map<String, Object?> toJson({required int max}) => <String, Object?>{
    'date': date,
    'used': usedToday(),
    'max': max,
    'remaining': remainingFor(max),
    'file': file.path,
  };

  /// [max] <= 0 表示不限。
  bool allows(int max) => max <= 0 || usedToday() < max;

  /// 记一条；只在公开 Issue 创建成功后调用。
  void record() {
    final next = usedToday() + 1;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(<String, Object?>{'date': _day(_today), 'count': next}));
  }

  ({String date, int count})? _read() {
    if (!file.existsSync()) return null;
    try {
      final data = jsonDecode(file.readAsStringSync());
      if (data is! Map) return null;
      final date = data['date'];
      final count = data['count'];
      if (date is! String || count is! int || count < 0) return null;
      return (date: date, count: count);
    } on FormatException {
      return null;
    }
  }

  static String _day(DateTime d) => d.toIso8601String().substring(0, 10);
}
