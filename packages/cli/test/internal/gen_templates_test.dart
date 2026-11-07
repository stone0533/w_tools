import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/gen_templates.dart' as gen;

void main() {
  test('CLI-011 行内 @if 标记必须被拒绝', () {
    final root = Directory.systemTemp.createTempSync('wt_gen_templates_');
    addTearDown(() => root.deleteSync(recursive: true));

    final source = Directory('templates');
    for (final entity in source.listSync(recursive: true).whereType<File>()) {
      final relative = p.relative(entity.path, from: source.path);
      final target = File(p.join(root.path, 'templates', relative));
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(entity.readAsBytesSync());
    }

    // 行内 marker 不会被当前渲染器/校验器识别，必须显式拒绝。
    File(
      p.join(root.path, 'templates', 'agents', 'zh', 'base.md'),
    ).writeAsStringSync('前置 <!-- @if:ui --> 后置\n');

    expect(() => gen.generate(root.path), throwsA(isA<StateError>()));
  });

  test('CLI-011 Windows 相对路径统一为 /', () {
    expect(gen.normalizeTemplatePath(r'agents\zh\base.md'), 'agents/zh/base.md');
  });
}
