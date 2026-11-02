import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('example/run_demo.sh 可离线执行', () async {
    final result = await Process.run(
      'bash',
      <String>['example/run_demo.sh'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('# Demo Page'));
    expect('${result.stdout}', contains('## 颜色'));
    expect('${result.stdout}', contains('Primary Button'));
  });
}
