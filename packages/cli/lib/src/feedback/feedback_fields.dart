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

/// 按行首 `- 字段：` 提取字段名。
final feedbackFieldLine = RegExp(r'^\s*-\s*(.+?)\s*[：:]');

/// 从一段 Markdown 中提取已填写的字段名。
Set<String> feedbackFieldsIn(String text) {
  final present = <String>{};
  for (final line in text.split('\n')) {
    final m = feedbackFieldLine.firstMatch(line);
    if (m != null) present.add(m.group(1)!.trim());
  }
  return present;
}

/// 返回缺失的必填字段（展示第一个别名）。
List<String> missingFeedbackFields(String text) {
  final present = feedbackFieldsIn(text);
  return [
    for (final aliases in feedbackRequiredFields)
      if (!aliases.any((a) => present.any((key) => key.startsWith(a)))) aliases.first,
  ];
}
