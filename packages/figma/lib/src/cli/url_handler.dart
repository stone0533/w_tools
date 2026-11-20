import 'dart:convert';
import 'dart:io';

import 'args.dart';
import 'cli_io.dart';

void runUrl(List<String> args) {
  final options = parseCommand(args, 'url');

  rejectExtra(options, 1);
  if (options.positional.isEmpty) {
    stderr.writeln('url 需要 Figma 链接');
    exitCode = 2;
    return;
  }
  final target = parseFigmaUrl(options.positional.first);
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

/// 从 Figma 链接解析 `fileKey` 与 `nodeId`；只接受 Figma 链接。
({String fileKey, String? nodeId}) parseFigmaUrl(String input) {
  if (input.contains('figma.com')) {
    final uri = Uri.tryParse(input);
    if (uri == null) {
      throw FormatException('不是合法的 URL：$input');
    }
    final segments = uri.pathSegments;
    final keyIndex = segments.indexWhere(
      (s) => s == 'design' || s == 'file' || s == 'proto',
    );
    if (keyIndex < 0 || segments.length <= keyIndex + 1) {
      throw FormatException('URL 里找不到 fileKey：$input');
    }
    final nodeRaw = uri.queryParameters['node-id'];
    return (fileKey: segments[keyIndex + 1], nodeId: nodeRaw?.replaceAll('-', ':'));
  }
  throw FormatException('需要一个 Figma 链接：$input');
}
