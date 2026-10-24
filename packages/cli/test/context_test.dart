import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';

Directory _project(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('wt_ctx_');
  files.forEach((rel, content) {
    final f = File(p.join(root.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });
  return root;
}

void main() {
  test('ignore 按目录边界匹配，不误伤同前缀目录', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart': 'void a() {}\n',
      'lib/app/generated/b.dart': 'void b() {}\n',
      'lib/app/generated2/c.dart': 'void c() {}\n',
    });
    final config = DoctorConfig(ignore: const <String>['lib/app/generated']);
    final ctx = ProjectContext.load(root, config);
    expect(ctx.files, contains('lib/a.dart'));
    expect(ctx.files, isNot(contains('lib/app/generated/b.dart')));
    // 只是前缀相同，不是同一目录
    expect(ctx.files, contains('lib/app/generated2/c.dart'));
  });

  test('默认跳过 .g.dart / .freezed.dart', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart': 'void a() {}\n',
      'lib/a.g.dart': 'void g() {}\n',
      'lib/a.freezed.dart': 'void f() {}\n',
    });
    final ctx = ProjectContext.load(root, DoctorConfig());
    expect(ctx.files, ['lib/a.dart']);
  });

  test('includeTests 才会扫描 test/ 与 tool/', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart': 'void a() {}\n',
      'test/a_test.dart': 'void t() {}\n',
      'tool/t.dart': 'void t() {}\n',
    });
    expect(ProjectContext.load(root, DoctorConfig()).files, ['lib/a.dart']);
    final all = ProjectContext.load(root, DoctorConfig(), includeTests: true).files;
    expect(all, containsAll(<String>['lib/a.dart', 'test/a_test.dart', 'tool/t.dart']));
  });

  test('name 取自 pubspec，缺省时退回目录名', () {
    final root = _project({'pubspec.yaml': 'name: my_app\n'});
    expect(ProjectContext.load(root, DoctorConfig()).name, 'my_app');

    final bare = Directory.systemTemp.createTempSync('wt_ctx_bare_');
    expect(ProjectContext.load(bare, DoctorConfig()).name, p.basename(bare.path));
  });

  test('filesUnder 只返回指定前缀', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/a.dart': 'void a() {}\n',
      'lib/app/design_system/x.dart': 'void x() {}\n',
    });
    final ctx = ProjectContext.load(root, DoctorConfig());
    expect(ctx.filesUnder('lib/app/design_system'), ['lib/app/design_system/x.dart']);
  });
}
