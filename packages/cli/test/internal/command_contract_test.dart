import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/context/context_project.dart';

/// 从当前目录向上找仓库根（含 workspace: 的 pubspec.yaml）。
Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && pubspec.readAsStringSync().contains('workspace:')) {
      return dir;
    }
    if (dir.path == dir.parent.path) {
      throw StateError('找不到仓库根（含 workspace: 的 pubspec.yaml）');
    }
    dir = dir.parent;
  }
}

String _section(String text, String heading, {String? endHeading}) {
  final start = text.indexOf(heading);
  if (start < 0) {
    fail('找不到章节：$heading');
  }
  final rest = text.substring(start + heading.length);
  if (endHeading != null) {
    final end = rest.indexOf(endHeading);
    if (end >= 0) return rest.substring(0, end);
  }
  return rest;
}

/// 取 markdown 表格里的命令名：单元格里的反引号内容，取第一个词。
///
/// 例：`upgrade --check` → upgrade；`list <关键词>` → list；
/// `--format=prompt` 不是命令，忽略。
Set<String> _tableCommands(String section, {required int commandCell}) {
  final result = <String>{};
  for (final line in section.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    final cells = trimmed.split('|').map((cell) => cell.trim()).toList();
    if (cells.length <= commandCell) continue;
    final cell = cells[commandCell];
    for (final match in RegExp(r'`([^`]+)`').allMatches(cell)) {
      final token = match.group(1)!.trim().split(RegExp(r'\s+')).first;
      if (RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(token)) {
        result.add(token);
      }
    }
  }
  return result;
}

void main() {
  late Directory root;
  late String dispatcher;
  late Set<String> commands;
  late Set<String> readmeCommands;
  late Set<String> exitCommands;
  late Set<String> agentsCommands;
  late Map<String, String> contextCommands;

  setUpAll(() {
    root = _repoRoot();
    dispatcher = File(
      p.join(root.path, 'packages/cli/bin/w_tools.dart'),
    ).readAsStringSync();
    commands = RegExp(
      r"case '([a-z0-9-]+)':",
    ).allMatches(dispatcher).map((match) => match.group(1)!).toSet();
    expect(commands, isNotEmpty, reason: 'dispatcher 里没有解析到命令');

    final readme = File(
      p.join(root.path, 'packages/cli/README.md'),
    ).readAsStringSync();
    final agents = File(
      p.join(root.path, 'docs/agents/cli.md'),
    ).readAsStringSync();
    readmeCommands = _tableCommands(
      _section(readme, '## 命令怎么选', endHeading: '## 退出码'),
      commandCell: 2,
    );
    exitCommands = _tableCommands(
      _section(readme, '## 退出码'),
      commandCell: 1,
    );
    agentsCommands = _tableCommands(
      _section(agents, '## 命令选择', endHeading: '## AI 闭环'),
      commandCell: 2,
    );
    contextCommands = ProjectSnapshot.load(root).commands();
  });

  test('每个 dispatcher 命令都有 README / docs / context / bin 落点', () {
    for (final command in commands) {
      expect(
        readmeCommands,
        contains(command),
        reason: 'packages/cli/README.md 的「命令怎么选」表缺 `$command`',
      );
      expect(
        exitCommands,
        contains(command),
        reason: 'packages/cli/README.md 的「退出码」表缺 `$command`',
      );
      expect(
        agentsCommands,
        contains(command),
        reason: 'docs/agents/cli.md 的「命令选择」表缺 `$command`',
      );
      expect(
        contextCommands.values.any(
          (value) => value.contains('w_tools $command'),
        ),
        isTrue,
        reason: 'ProjectSnapshot.commands() 没有任何 value 含 `w_tools $command`',
      );
      expect(
        File(p.join(root.path, 'packages/cli/bin/$command.dart')).existsSync(),
        isTrue,
        reason: '缺少 packages/cli/bin/$command.dart',
      );
    }
  });

  test('表格里没有 dispatcher 之外的命令', () {
    // 退出码表里有 `feedback path` / `lint` 这类子命令，不能可靠反推顶层命令；
    // 反向检查只覆盖两张「命令怎么选」表。
    final tables = <String, Set<String>>{
      'packages/cli/README.md 命令表': readmeCommands,
      'docs/agents/cli.md 命令表': agentsCommands,
    };
    for (final entry in tables.entries) {
      final unknown = entry.value.difference(commands);
      expect(
        unknown,
        isEmpty,
        reason: '${entry.key} 出现 dispatcher 没有的命令：${unknown.join(', ')}',
      );
    }
  });
}
