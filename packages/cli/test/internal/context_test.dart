import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/context/context_project.dart';
import 'package:w_tools_cli/src/context/install_info.dart';
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

  test('commands 里包含 feedback 入口（AI 通过 context 能发现）', () {
    final root = _project({'pubspec.yaml': 'name: demo\n'});
    addTearDown(() => root.deleteSync(recursive: true));
    final json = ProjectSnapshot.load(root).toJson();
    final commands = json['commands'] as Map<String, String>;
    expect(commands['feedbackStatus'], contains('feedback status'));
    expect(commands['feedbackSubmit'], contains('feedback submit'));
    expect(commands['feedbackLint'], contains('feedback lint'));
    expect(commands['list'], contains('list'));
    expect(commands['explain'], contains('explain'));
    expect(commands['upgradeCheck'], contains('upgrade --check'));
    expect(commands['upgrade'], contains('w_tools upgrade'));
  });

  test('context 暴露已安装能力摘要', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\ndependencies:\n  w_tools_async: ^5.0.0\n',
      'pubspec.lock': '''
packages:
  w_tools_async:
    dependency: "direct main"
    description:
      name: w_tools_async
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
''',
    });
    addTearDown(() => root.deleteSync(recursive: true));
    final snapshot = ProjectSnapshot.load(root);
    final caps = snapshot.toJson()['capabilities'] as List;
    expect(caps, isNotEmpty);
    expect(
      caps.any((e) => (e as Map)['package'] == 'w_tools_async'),
      isTrue,
    );
    expect(snapshot.toPrompt(), contains('WAsyncController'));
  });

  test('安装 w_tools_device 时 context 暴露设备命令', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\ndev_dependencies:\n  w_tools_device: ^0.1.2\n',
      'pubspec.lock': '''
packages:
  w_tools_device:
    dependency: "direct dev"
    description:
      name: w_tools_device
      url: "https://pub.dev"
    source: hosted
    version: "0.1.2"
''',
    });
    addTearDown(() => root.deleteSync(recursive: true));
    final commands = ProjectSnapshot.load(root).commands();
    expect(commands['deviceList'], contains('w_tools_device:device list'));
    expect(commands['deviceShot'], contains('device shot'));
    expect(commands['deviceForeground'], contains('foreground --android'));
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

  test('toolkitExports 支持带数字的包名', () {
    final root = _project({
      'pubspec.yaml': 'name: demo\n',
      'lib/app/w/toolkit.dart':
          "export 'package:w_tools_e2e/e2e.dart';\n"
          "export 'package:w_tools_ui/w_tools_ui.dart';\n",
    });
    final ctx = ProjectContext.load(root, DoctorConfig());
    expect(ctx.facts.toolkitExports, containsAll(<String>['w_tools_e2e', 'w_tools_ui']));
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
  test('仓库检出时已装文案不写（无）', () {
    final root = _project({
      'pubspec.yaml': 'name: w_tools\n',
      'pubspec.lock': 'packages:\n  args:\n    version: "2.6.0"\n',
    });
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
    final snapshot = ProjectSnapshot.load(root);
    expect(snapshot.repoCheckout, isTrue);
    final prompt = snapshot.toPrompt();
    expect(prompt, contains('仓库检出'));
    expect(prompt, isNot(contains('已装(w_tools/直接依赖): （无）')));
    expect(prompt, contains('workspace 包不在 pubspec.lock'));
  });
  _installTests();
}

void _installTests() {
  test('install：从 package_config 解析 w_tools_cli 位置，并识别仓库检出', () {
    final root = Directory.systemTemp.createTempSync('wt_install_');
    addTearDown(() => root.deleteSync(recursive: true));
    final pkg = Directory(p.join(root.path, 'repo', 'packages', 'cli'))
      ..createSync(recursive: true);
    File(p.join(root.path, 'repo', 'docs', 'feedback', 'README.md')).createSync(recursive: true);
    File(p.join(pkg.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');

    final project = Directory(p.join(root.path, 'app'))..createSync();
    File(p.join(project.path, '.dart_tool', 'package_config.json')).createSync(recursive: true);
    File(p.join(project.path, '.dart_tool', 'package_config.json')).writeAsStringSync(
      '{"configVersion":2,"packages":[{"name":"w_tools_cli",'
      '"rootUri":"${pkg.uri}"}]}',
    );

    final info = InstallInfo.detect(projectRoot: project);
    expect(info.packageRoot, pkg.path);
    expect(info.repoRoot, p.join(root.path, 'repo'));
    expect(info.isRepoCheckout, isTrue);
    expect(info.feedbackDir, p.join(root.path, 'repo', 'docs', 'feedback'));
  });

  test('install：不从仓库检出时（如 pub cache）feedbackDir 为 null', () {
    final root = Directory.systemTemp.createTempSync('wt_install2_');
    addTearDown(() => root.deleteSync(recursive: true));
    // 模拟 pub cache：<cache>/w_tools-abc/packages/cli，没有 docs/feedback
    final pkg = Directory(p.join(root.path, 'cache', 'w_tools-abc', 'packages', 'cli'))
      ..createSync(recursive: true);
    File(p.join(pkg.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
    final project = Directory(p.join(root.path, 'app'))..createSync();
    final config = File(p.join(project.path, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true);
    config.writeAsStringSync(
      '{"configVersion":2,"packages":[{"name":"w_tools_cli",'
      '"rootUri":"${pkg.uri}"}]}',
    );

    final info = InstallInfo.detect(projectRoot: project);
    expect(info.packageRoot, pkg.path);
    expect(info.isRepoCheckout, isFalse);
    expect(info.feedbackDir, isNull, reason: '不是仓库检出就不该写库侧');
  });
}
