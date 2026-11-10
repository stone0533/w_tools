import 'dart:convert';
import 'dart:io';

import '../commands/url_command.dart';
import 'args.dart';
import 'cli_io.dart';

void runUrl(List<String> args) {
  final options = parseOptions(args);
  rejectUnsupported(options, {'root', 'json'});

  rejectExtraPositional(options, 1);
  if (options.seen.contains('root')) {
    stderr.writeln('# --root 对 url 没有作用（已弃用，remove-in: 0.14.0）');
  }
  if (options.positional.isEmpty) {
    stderr.writeln('url 需要 Figma 链接或 nodeId');
    exitCode = 2;
    return;
  }
  final target = const UrlCommand().run(options.positional.first);
  if (options.json) {
    printLine(jsonEncode({
      'schema': 'w_tools_figma.url/1',
      'fileKey': target.fileKey,
      'nodeId': target.nodeId,
    }));
    return;
  }
  printLine('fileKey=${target.fileKey}  nodeId=${target.nodeId ?? ''}');
}
