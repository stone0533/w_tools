// 编译冒烟检查：把 init 生成的 UI starter 放进 ui example 的临时目录，
// 让 Flutter 解析 package:w_tools_ui，并执行 flutter analyze。
//
// 用法（在 packages/cli 下）：
//   dart run tool/check_templates_compile.dart
//
// 需要 Flutter SDK；CI 的 CLI job 会跑它。
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/init/templates.dart';

Future<void> main() async {
  final cliRoot = Directory.current;
  final repoRoot = cliRoot.parent.parent;
  final exampleRoot = Directory(p.join(repoRoot.path, 'packages', 'ui', 'example'));

  if (!exampleRoot.existsSync()) {
    stderr.writeln('找不到 ui example：${exampleRoot.path}');
    exit(2);
  }

  final temp = exampleRoot.createTempSync('.generated_templates_check_');
  try {
    final files = <String, String>{
      'app_bars.dart': InitTemplates.appBars(),
      'app_boxes.dart': InitTemplates.appBoxes(),
      'app_buttons.dart': InitTemplates.appButtons(),
      'app_card.dart': InitTemplates.appCard(),
      'app_scaffold.dart': InitTemplates.appScaffold(),
    };
    for (final entry in files.entries) {
      File(p.join(temp.path, entry.key)).writeAsStringSync(entry.value);
    }

    final pubGet = await Process.run(
      'flutter',
      const ['pub', 'get'],
      workingDirectory: exampleRoot.path,
    );
    if (pubGet.exitCode != 0) {
      stdout.write(pubGet.stdout);
      stderr.write(pubGet.stderr);
      stderr.writeln('flutter pub get 失败');
      exitCode = 1;
      return;
    }

    final analyze = await Process.run(
      'flutter',
      [
        'analyze',
        temp.path,
        '--no-fatal-infos',
        '--no-fatal-warnings',
      ],
      workingDirectory: exampleRoot.path,
    );
    stdout.write(analyze.stdout);
    stderr.write(analyze.stderr);
    if (analyze.exitCode != 0) {
      stderr.writeln('生成模板编译检查失败');
      exitCode = 1;
    }
  } finally {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  }
}
