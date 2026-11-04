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
  'design_system_README.en.md': 'designSystemReadmeEn',
  'agents/zh/base.md': 'agentsBase',
  'agents/zh/feedback.md': 'agentsFeedback',
  'agents/zh/closing.md': 'agentsClosing',
  'agents/zh/ui.md': 'agentsUi',
  'agents/zh/form.md': 'agentsForm',
  'agents/zh/api.md': 'agentsApi',
  'agents/zh/app.md': 'agentsApp',
  'agents/zh/async.md': 'agentsAsync',
  'agents/zh/toast.md': 'agentsToast',
  'agents/zh/core.md': 'agentsCore',
  'agents/zh/qr.md': 'agentsQr',
  'agents/zh/map.md': 'agentsMap',
  'agents/zh/figma.md': 'agentsFigma',
  'agents/zh/device.md': 'agentsDevice',
  'agents/en/base.md': 'agentsBaseEn',
  'agents/en/feedback.md': 'agentsFeedbackEn',
  'agents/en/closing.md': 'agentsClosingEn',
  'agents/en/ui.md': 'agentsUiEn',
  'agents/en/form.md': 'agentsFormEn',
  'agents/en/api.md': 'agentsApiEn',
  'agents/en/app.md': 'agentsAppEn',
  'agents/en/async.md': 'agentsAsyncEn',
  'agents/en/toast.md': 'agentsToastEn',
  'agents/en/core.md': 'agentsCoreEn',
  'agents/en/qr.md': 'agentsQrEn',
  'agents/en/map.md': 'agentsMapEn',
  'agents/en/figma.md': 'agentsFigmaEn',
  'agents/en/device.md': 'agentsDeviceEn',
  'ui_README.md': 'uiReadme',
  'ui_README.en.md': 'uiReadmeEn',
  'device/device_smoke.dart.tpl': 'deviceSmokeScript',
  'device/device-testing.md.tpl': 'deviceTestingDoc',
  'device/gradle-mirror.init.gradle.example.tpl': 'deviceGradleMirror',
  'app_bars.dart.tpl': 'appBarsTemplate',
  'app_boxes.dart.tpl': 'appBoxesTemplate',
  'app_buttons.dart.tpl': 'appButtonsTemplate',
  'app_card.dart.tpl': 'appCardTemplate',
  'app_scaffold.dart.tpl': 'appScaffoldTemplate',
};

String generate(String repoRoot) {
  // 模板目录与注册表必须一一对应：新增文件忘记登记会在这里失败。
  final templatesDir = Directory(p.join(repoRoot, 'templates'));
  final actual = templatesDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => p.relative(f.path, from: templatesDir.path).replaceAll(r'\\', '/'))
      .where((rel) => rel != 'README.md')
      .toSet();
  final missing = actual.difference(_templates.keys.toSet());
  if (missing.isNotEmpty) {
    throw StateError('模板未登记到 _templates：${missing.join(', ')}');
  }

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
