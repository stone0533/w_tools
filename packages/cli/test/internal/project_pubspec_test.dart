import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/common/project_pubspec.dart';

Directory _project(String pubspec) {
  final root = Directory.systemTemp.createTempSync('wt_pubspec_');
  addTearDown(() => root.deleteSync(recursive: true));
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
  return root;
}

void main() {
  test('ProjectPubspec 统一暴露 name / Flutter / 聚合包 / 约束', () {
    final root = _project('''
name: demo_app
dependencies:
  flutter:
    sdk: flutter
  w_tools: any
  w_tools_figma:
    path: ../figma
''');
    final pubspec = ProjectPubspec.load(root);
    expect(pubspec.declaredName, 'demo_app');
    expect(pubspec.isFlutter, isTrue);
    expect(pubspec.usesAggregate, isTrue);
    expect(pubspec.hasDependency('w_tools_figma'), isTrue);
    expect(pubspec.constraint('w_tools_figma'), isNull);
  });

  test('ProjectPubspec 对坏 YAML 返回 parseError，不抛异常', () {
    final root = _project('name: [unterminated\n');
    final pubspec = ProjectPubspec.load(root);
    expect(pubspec.parseError, isNotNull);
    expect(pubspec.declaredName, isNull);
  });
}
