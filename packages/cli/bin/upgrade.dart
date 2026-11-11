// ignore_for_file: avoid_print

import 'dart:io';

import 'package:w_tools_cli/src/upgrade/upgrade_command.dart' as upgrade;

Future<void> main(List<String> argv) async {
  exitCode = (await upgrade.run(argv)).exitCode;
}
