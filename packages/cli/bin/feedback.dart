import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/feedback/feedback_command.dart' as command;

CommandResult run(List<String> argv) => command.run(argv);

void main(List<String> argv) {
  exitCode = run(argv).exitCode;
}
