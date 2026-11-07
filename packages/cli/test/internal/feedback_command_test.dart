import 'package:test/test.dart';
import 'package:w_tools_cli/src/feedback/feedback_command.dart' as command;

void main() {
  test('CLI-018 feedback 命令层可在进程内调用（不再只存在于 bin）', () {
    final result = command.run(const <String>['--version']);
    expect(result.exitCode, 0);
  });
}
