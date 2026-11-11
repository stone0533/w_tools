import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_budget.dart';

Directory _tmp(String prefix) => Directory.systemTemp.createTempSync(prefix);

void main() {
  test('没有文件时额度从 0 开始；record 后当天 +1', () {
    final root = _tmp('wt_budget_');
    addTearDown(() => root.deleteSync(recursive: true));
    final day = DateTime(2026, 11, 9, 10);
    final budget = FeedbackBudget(FeedbackBudget.fileFor(root), now: day);

    expect(budget.usedToday(), 0);
    expect(budget.allows(5), isTrue);

    budget.record();
    expect(budget.usedToday(), 1);
    expect(budget.file.existsSync(), isTrue);
  });

  test('date / remaining / toJson 给 status 和错误提示使用', () {
    final root = _tmp('wt_budget_status_');
    addTearDown(() => root.deleteSync(recursive: true));
    final day = DateTime(2026, 11, 9, 10);
    final budget = FeedbackBudget(FeedbackBudget.fileFor(root), now: day);
    budget.record();
    budget.record();

    expect(budget.date, '2026-11-09');
    expect(budget.remainingFor(5), 3);
    expect(budget.remainingFor(0), isNull, reason: 'max=0 表示不限');
    expect(budget.toJson(max: 5), {
      'date': '2026-11-09',
      'used': 2,
      'max': 5,
      'remaining': 3,
      'file': budget.file.path,
    });
  });

  test('额度用满后拒绝；max=0 表示不限', () {
    final root = _tmp('wt_budget_max_');
    addTearDown(() => root.deleteSync(recursive: true));
    final day = DateTime(2026, 11, 9, 10);
    final budget = FeedbackBudget(FeedbackBudget.fileFor(root), now: day);
    for (var i = 0; i < 5; i++) {
      expect(budget.allows(5), isTrue, reason: '第 ${i + 1} 条应放行');
      budget.record();
    }
    expect(budget.allows(5), isFalse);
    expect(budget.allows(0), isTrue, reason: 'max=0 是关闭额度');

    // 额度耗尽后再记也不该越过上限（调用方不该走到这里，但别写出 6）
    budget.record();
    expect(budget.usedToday(), 6);
    expect(budget.allows(10), isTrue);
  });

  test('跨天自动归零（旧日期不计入今天）', () {
    final root = _tmp('wt_budget_day_');
    addTearDown(() => root.deleteSync(recursive: true));
    final file = FeedbackBudget.fileFor(root)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'date': '2026-11-08', 'count': 5}));

    final today = FeedbackBudget(file, now: DateTime(2026, 11, 9, 9));
    expect(today.usedToday(), 0);
    expect(today.allows(5), isTrue);

    today.record();
    expect(
      jsonDecode(file.readAsStringSync()),
      {'date': '2026-11-09', 'count': 1},
    );
    expect(p.basename(file.path), 'feedback_budget.json');
  });

  test('文件损坏 / 字段类型不对时按 0 处理，不抛异常', () {
    final root = _tmp('wt_budget_bad_');
    addTearDown(() => root.deleteSync(recursive: true));
    final file = FeedbackBudget.fileFor(root)..parent.createSync(recursive: true);

    file.writeAsStringSync('not json');
    expect(FeedbackBudget(file).usedToday(), 0);

    file.writeAsStringSync(jsonEncode({'date': '2026-11-09', 'count': '5'}));
    expect(FeedbackBudget(file).usedToday(), 0);

    file.writeAsStringSync(jsonEncode({'date': '2026-11-09', 'count': -1}));
    expect(FeedbackBudget(file).usedToday(), 0);
  });
}
