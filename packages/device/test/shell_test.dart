import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_device/w_tools_device.dart';

void main() {
  test('命令超时抛 ProcessException，而不是一直挂着', () async {
    const shell = ProcessShell(timeout: Duration(milliseconds: 100));
    await expectLater(
      shell.run('sleep', ['2']),
      throwsA(
        isA<ProcessException>().having(
          (e) => e.message,
          'message',
          contains('超时'),
        ),
      ),
    );
  });

  test('正常命令不受影响', () async {
    const shell = ProcessShell();
    final r = await shell.run('echo', ['ok']);
    expect(r.exitCode, 0);
    expect('${r.stdout}'.trim(), 'ok');
  });
}
