import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/init/templates.dart';

import '../tool/gen_templates.dart';

/// 漂移守卫：`lib/src/init/templates.g.dart` 必须与仓库根 `templates/` 一致。
///
/// 改了 templates/ 却忘了跑 `dart run tool/gen_templates.dart`，这条测试会红。
Directory cliRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && pubspec.readAsStringSync().contains('name: w_tools_cli')) {
      return dir;
    }
    dir = dir.parent;
  }
  throw StateError('找不到 w_tools_cli 包根');
}

void main() {
  final repoRoot = cliRoot().path;

  test('templates.g.dart 与 templates/ 内容一致', () {
    final committed = File(
      p.join(repoRoot, 'lib', 'src', 'init', 'templates.g.dart'),
    ).readAsStringSync();
    expect(
      committed,
      generate(repoRoot),
      reason: '改了 templates/ 之后要跑 `dart run tool/gen_templates.dart`',
    );
  });

  test('生成的常量能按开关剔除可选 export', () {
    final all = InitTemplates.toolkit(withQr: true, withMap: true);
    expect(all, contains("export 'package:w_tools_qr/w_tools_qr.dart';"));
    expect(all, contains("export 'package:w_tools_map/w_tools_map.dart';"));

    final minimal = InitTemplates.toolkit(withQr: false, withMap: false);
    expect(minimal, isNot(contains("export 'package:w_tools_qr")));
    expect(minimal, isNot(contains("export 'package:w_tools_map")));
    expect(minimal, contains("export 'package:w_tools_ui/w_tools_ui.dart';"));
  });

  test('AGENTS 片段带标记块（init 靠它幂等替换）', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('<!-- w_tools:begin -->'));
    expect(block, contains('<!-- w_tools:end -->'));
  });
}
