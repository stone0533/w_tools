import 'dart:io';

import '../commands/url_command.dart';
import 'cli_io.dart';

void runUrl(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('url 需要 Figma 链接或 nodeId');
    exitCode = 2;
    return;
  }
  final target = const UrlCommand().run(args.first);
  printLine('fileKey=${target.fileKey}  nodeId=${target.nodeId ?? ''}');
}
