/// CLI 命令的机器面注册表。
///
/// 只收拢两处：
/// - `bin/w_tools.dart` 的 `_usage` 命令段；
/// - `context` 的 `commands` 示例。
///
/// README / docs/agents 的人写表格仍由 `command_contract_test` 校验，不从这里生成，
/// 避免把散文排版锁死。
class CliCommand {
  const CliCommand({
    required this.name,
    required this.summary,
    required this.examples,
  });

  final String name;
  final String summary;

  /// `context.commands` 的 key → 完整命令行；一个顶层命令可以有多个示例。
  final Map<String, String> examples;
}

const cliCommands = <CliCommand>[
  CliCommand(
    name: 'init',
    summary: '把 w_tools 接入项目',
    examples: <String, String>{
      'initCheck': 'dart run w_tools_cli:w_tools init --check-drift',
    },
  ),
  CliCommand(
    name: 'doctor',
    summary: '检查项目是否遵守接入约定',
    examples: <String, String>{
      'doctor': 'dart run w_tools_cli:w_tools doctor --json',
    },
  ),
  CliCommand(
    name: 'context',
    summary: '输出项目事实（AI / CI）',
    examples: <String, String>{
      'context': 'dart run w_tools_cli:w_tools context --format=json',
    },
  ),
  CliCommand(
    name: 'list',
    summary: '查组件目录',
    examples: <String, String>{
      'list': 'dart run w_tools_cli:w_tools list <关键词> --format=prompt',
    },
  ),
  CliCommand(
    name: 'explain',
    summary: '解释一个组件',
    examples: <String, String>{
      'explain': 'dart run w_tools_cli:w_tools explain <组件名> --format=prompt',
    },
  ),
  CliCommand(
    name: 'upgrade',
    summary: '把 w_tools 系依赖抬到 pub 最新',
    examples: <String, String>{
      'upgradeCheck': 'dart run w_tools_cli:w_tools upgrade --check',
      'upgrade': 'dart run w_tools_cli:w_tools upgrade',
    },
  ),
  CliCommand(
    name: 'feedback',
    summary: '提交 w_tools 反馈',
    examples: <String, String>{
      'feedbackStatus': 'dart run w_tools_cli:w_tools feedback status',
      'feedbackSubmit':
          'dart run w_tools_cli:w_tools feedback submit --package=<包> --title=<标题> --stdin',
      'feedbackLint': 'dart run w_tools_cli:w_tools feedback lint --include-inbox',
    },
  ),
];

/// `w_tools --help` 里「命令：」段的正文（不含标题 / 结尾换行）。
String commandUsageLines() =>
    cliCommands.map((command) => '  ${command.name.padRight(11)}${command.summary}').join('\n');

/// `context.commands` 的 CLI 部分；调用方可以继续 addAll analyze / test / device。
Map<String, String> contextCommandExamples() => <String, String>{
  for (final command in cliCommands) ...command.examples,
};
