import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/context/context_project.dart';

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

Directory project() {
  final root = Directory.systemTemp.createTempSync('wt_schema_');
  addTearDown(() => root.deleteSync(recursive: true));
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
    'name: demo_app\nenvironment:\n  sdk: ^3.10.0\ndependencies: {}\n',
  );
  return root;
}

void main() {
  test('context v1 schema 文件与代码常量一致', () {
    final file = File(p.join(cliRoot().path, 'schema', 'context.v1.json'));
    final schema = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(schema['properties']['schema']['const'], contextSchema);
    expect(schema['properties']['schemaVersion']['const'], contextSchemaVersion);
    expect(schema['additionalProperties'], isTrue);
    expect(schema['required'], contains('schema'));
    expect(schema['required'], contains('schemaVersion'));
    expect(schema['required'], contains('project'));
  });

  test('带 doctor issue 的 context JSON 也符合 v1 schema', () {
    final root = Directory.systemTemp.createTempSync('wt_schema_issue_');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
      'name: demo_app\n'
      'environment:\n  sdk: ^3.10.0\n'
      'dependencies:\n  w_tools: any\n',
    );

    final schemaFile = File(p.join(cliRoot().path, 'schema', 'context.v1.json'));
    final schema = JsonSchema.create(jsonDecode(schemaFile.readAsStringSync()));
    final snapshot = ProjectSnapshot.load(root);
    final json = snapshot.toJson();
    final doctor = json['doctor'] as Map<String, Object?>;
    final issues = doctor['issues'] as List<Object?>;

    expect(issues, isNotEmpty);
    final result = schema.validate(json);
    expect(
      result.isValid,
      isTrue,
      reason: result.errors.map((e) => '${e.instancePath}: ${e.message}').join('\n'),
    );
  });

  test('真实 context JSON 符合 v1 schema', () {
    final schemaFile = File(p.join(cliRoot().path, 'schema', 'context.v1.json'));
    final schema = JsonSchema.create(jsonDecode(schemaFile.readAsStringSync()));
    final snapshot = ProjectSnapshot.load(project());
    final result = schema.validate(snapshot.toJson());

    expect(
      result.isValid,
      isTrue,
      reason: result.errors.map((e) => '${e.instancePath}: ${e.message}').join('\n'),
    );
  });
}
