import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/doctor/config.dart';

/// 防漂移：`--print-config` 渲染出来的文本，解析回去必须等于代码里的默认值。
///
/// 改了 [DoctorConfig] 的默认值却忘了改渲染逻辑，这条会红。
void main() {
  test('渲染的默认配置能解析回同一份默认值', () {
    final parsed = DoctorConfig.parse(renderDefaultConfig());
    final defaults = DoctorConfig();

    expect(parsed.toolkitEntry, defaults.toolkitEntry);
    expect(parsed.designSystemDir, defaults.designSystemDir);
    expect(parsed.palette, isEmpty, reason: 'R3 调色板默认必须是空（不配置就跳过）');
    expect(parsed.colorMinCount, defaults.colorMinCount);
    expect(parsed.enabledRules, defaults.enabledRules);
    expect(parsed.ignore, isEmpty);
  });

  test('渲染文本里的 R6 与 palette 都是注释掉的', () {
    final text = renderDefaultConfig();
    expect(text, contains('# R6: true'));
    expect(text, contains('# palette:'));
    // 未注释的 key 只有这几个
    final activeKeys = text
        .split('\n')
        .where((l) => l.isNotEmpty && !l.trimLeft().startsWith('#') && l.contains(':'))
        .map((l) => l.split(':').first.trim())
        .toSet();
    expect(
      activeKeys,
      containsAll(<String>['toolkit_entry', 'design_system_dir', 'colors', 'rules', 'ignore']),
    );
  });

  test('取消注释 palette 后能生效', () {
    final text = renderDefaultConfig().replaceFirst(
      '# palette: ["#3F3F3F", "#545454", "#EAEAEA"]',
      'palette: ["#3F3F3F", "#545454", "#EAEAEA"]',
    );
    final parsed = DoctorConfig.parse(text);
    expect(parsed.palette, containsAll(<String>['#3F3F3F', '#545454', '#EAEAEA']));
  });

  test('取消注释 rules.R6 后能生效', () {
    final text = renderDefaultConfig().replaceFirst('# R6: true', 'R6: true');
    expect(DoctorConfig.parse(text).enabledRules, contains('R6'));
  });

  test('--write-config 的落盘内容与默认配置一致', () {
    final root = Directory.systemTemp.createTempSync('wt_cfg_');
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    File(p.join(root.path, DoctorConfig.fileName)).writeAsStringSync(renderDefaultConfig());

    final loaded = DoctorConfig.load(root);
    expect(loaded.toolkitEntry, DoctorConfig().toolkitEntry);
    expect(loaded.palette, isEmpty);
  });
}
