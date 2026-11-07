import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// 用户可见的命令入口必须统一走 dispatcher。
///
/// `bin/w_tools.dart` 里的“兼容入口仍保留”是唯一允许提到旧入口的地方；
/// `bin/*.dart` 的 `_usage`、doctor fix/hint、生成配置头、example 文档都不行。
void main() {
  test('CLI-001 用户可见入口统一 dispatcher，不再教 w_tools_cli:<cmd>', () {
    final files = <File>[
      ...Directory(
        'bin',
      ).listSync().whereType<File>().where((f) => p.basename(f.path) != 'w_tools.dart'),
      File(p.join('lib', 'src', 'doctor', 'config.dart')),
      File(p.join('lib', 'src', 'doctor', 'rules', 'r8_generated_stale.dart')),
      File(p.join('lib', 'src', 'feedback', 'feedback_command.dart')),
      File(p.join('lib', 'src', 'init', 'templates.dart')),
      File(p.join('example', 'README.md')),
      File(p.join('schema', 'README.md')),
      File(p.join('..', '..', 'docs', 'agents', 'README.md')),
    ];
    final legacy = RegExp(r'w_tools_cli:(?:init|doctor|context|list|explain|feedback)\b');
    for (final file in files) {
      expect(
        legacy.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} 仍在教兼容入口，应改为 w_tools_cli:w_tools <cmd>',
      );
    }
  });
}
