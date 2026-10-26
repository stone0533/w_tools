import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/common/version.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('cliVersion 与 pubspec.yaml 的 version 一致', () {
    final raw = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    expect(cliVersion, raw['version']);
  });
}
