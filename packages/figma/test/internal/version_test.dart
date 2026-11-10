import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/version.dart';

void main() {
  test('figmaVersion 与 pubspec.yaml 的 version 一致', () {
    final raw = File('pubspec.yaml').readAsLinesSync();
    final line = raw.firstWhere((l) => l.startsWith('version:'));
    expect(figmaVersion, line.substring('version:'.length).trim());
  });
}
