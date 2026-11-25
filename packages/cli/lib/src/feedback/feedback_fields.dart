// 反馈字段的唯一定义：`submit` 校验与维护者 lint 共用。

/// 待处理 / 提交反馈必须出现的字段（中英文均可）。
const feedbackRequiredFields = <List<String>>[
  ['包/版本', 'package/version'],
  ['环境', 'environment'],
  ['命令', 'command'],
  ['期望', 'expected'],
  ['实际', 'actual'],
  ['影响', 'impact'],
  ['建议', 'suggestion'],
  ['复现数据', 'repro'],
];

/// 字段行：必须从行首 `-` 开始。
///
/// 不匹配缩进列表项：`复现数据` / `建议` 里常写 `  - 现象：…` 这样的子项，
/// 它们不是字段；旧版 `^\s*-` 会把子项也算成字段，反过来让真正的字段值被截断。
final feedbackFieldLine = RegExp(r'^-\s*(.+?)\s*[：:]');

/// 解析字段值：冒号后到**下一个行首字段行**之前的全部内容都算这个字段的值。
///
/// 反馈里的命令 / 复现数据经常是多行代码块或列表；只看冒号后那一行会把
/// 合法内容误判成占位（CI 的 `check_feedback.sh` 会因此把整份台账判红）。
Map<String, String> feedbackFieldValues(String text) {
  final values = <String, String>{};
  String? key;
  final buffer = StringBuffer();
  void flush() {
    final current = key;
    if (current == null) return;
    values[current] = buffer.toString().trim();
  }

  for (final line in text.split('\n')) {
    final match = feedbackFieldLine.firstMatch(line);
    if (match != null) {
      flush();
      key = match.group(1)!.trim();
      buffer
        ..clear()
        ..write(line.substring(match.end).trim());
    } else if (key != null) {
      buffer
        ..write('\n')
        ..write(line);
    }
  }
  flush();
  return values;
}

/// 从一段 Markdown 中提取已填写的字段名。
Set<String> feedbackFieldsIn(String text) => feedbackFieldValues(text).keys.toSet();

/// 返回缺失的必填字段（展示第一个别名）。
List<String> missingFeedbackFields(String text) {
  final present = feedbackFieldsIn(text);
  return [
    for (final aliases in feedbackRequiredFields)
      if (!aliases.any((a) => present.any((key) => key.startsWith(a)))) aliases.first,
  ];
}
