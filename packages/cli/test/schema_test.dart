import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/context/context_project.dart';

void main() {
  test('context v1 schema 文件与代码常量一致', () {
    final file = File(p.join(Directory.current.path, 'schema', 'context.v1.json'));
    final schema = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(schema['properties']?['schema']?['const'], contextSchema);
    expect(schema['properties']?['schemaVersion']?['const'], contextSchemaVersion);
    expect(schema['additionalProperties'], isTrue);
    expect(schema['required'], contains('schema'));
    expect(schema['required'], contains('schemaVersion'));
    expect(schema['required'], contains('project'));
  });
}
