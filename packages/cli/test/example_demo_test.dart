import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('example/run_demo.sh 可完整执行', () async {
    final cliRoot = Directory.current.path;
    final result = await Process.run(
      'bash',
      [p.join('example', 'run_demo.sh')],
      workingDirectory: cliRoot,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('== doctor =='));
    expect(result.stdout, contains('0 error / 0 warning'));
    expect(result.stdout, contains('WForm'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
