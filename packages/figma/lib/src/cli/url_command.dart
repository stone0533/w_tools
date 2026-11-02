import 'dart:convert';
import 'dart:io';

import '../commands/url_command.dart';
import 'args.dart';
import 'cli_io.dart';

void runUrl(List<String> args) {
  final options = parseOptions(args);
  if (options.positional.isEmpty) {
    stderr.writeln('url 需要 Figma 链接或 nodeId');
    exitCode = 2;
    return;
  }
  final target = const UrlCommand().run(options.positional.first);
  if (options.json) {
    printLine(jsonEncode({'fileKey': target.fileKey, 'nodeId': target.nodeId}));
    return;
  }
  printLine('fileKey=${target.fileKey}  nodeId=${target.nodeId ?? ''}');
}
