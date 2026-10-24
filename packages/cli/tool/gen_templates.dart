// ignore_for_file: avoid_print

// 把 templates/ 下的模板文件生成成 Dart 常量（lib/src/init/templates.g.dart）。
//
// 为什么需要这一步：`init` 要在**消费方项目**里跑到 `lib/src/init/templates/*`，
// 但 `Isolate.resolvePackageUri` 在 flutter_test 等环境不可用（Unsupported operation），
// 运行时读文件不可靠。所以改成构建期生成常量 —— 模板文件仍是唯一来源，
// 漂移由 test/templates_fresh_test.dart 兜底。
//
// 用法：
//   dart run tool/gen_templates.dart          # 重新生成
//   dart run tool/gen_templates.dart --check  # 只校验是否过期（CI 用，过期退出码 1）
import 'dart:io';

import 'package:path/path.dart' as p;

const _templates = <String, String>{
  'toolkit.dart.tpl': 'toolkitTemplate',
  'design_system_README.md': 'designSystemReadme',
  'AGENTS_snippet.md': 'agentsSnippet',
};

String generate(String repoRoot) {
  final buf = StringBuffer()
    ..writeln('// 由 tool/gen_templates.dart 生成，不要手改。')
    ..writeln('// 模板源文件在 templates/（唯一来源）；改完跑 `dart run tool/gen_templates.dart`。')
    ..writeln('//')
    ..writeln('// dart format off')
    ..writeln('// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars')
    ..writeln();

  _templates.forEach((file, symbol) {
    final content = File(p.join(repoRoot, 'templates', file)).readAsStringSync();
    buf
      ..writeln('const String $symbol = r\'\'\'')
      ..write(content)
      ..writeln('\'\'\';')
      ..writeln();
  });
  return buf.toString();
}

void main(List<String> argv) {
  final repoRoot = Directory.current.path;
  final target = File(p.join(repoRoot, 'lib', 'src', 'init', 'templates.g.dart'));
  final generated = generate(repoRoot);
  final check = argv.contains('--check');

  if (check) {
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != generated) {
      stderr.writeln(
        'templates.g.dart 已过期：改了 templates/ 之后要跑 '
        '`dart run tool/gen_templates.dart`',
      );
      exit(1);
    }
    print('templates.g.dart 与 templates/ 一致 ✓');
    return;
  }

  target.writeAsStringSync(generated);
  print('已生成 ${p.relative(target.path, from: repoRoot)}');
}
