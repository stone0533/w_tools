import 'dart:io';

import 'args.dart';
import 'cli_io.dart';

/// 下载 fetch images 返回的签名 URL；不访问 Figma API，不消耗额度。
Future<void> runGet(List<String> args) async {
  final options = parseOptions(args);
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('get 用法：get <url> <outfile>');
    exitCode = 2;
    return;
  }
  final rawUrl = positional[0];
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw FormatException('get 需要 http(s) 图片 URL：$rawUrl');
  }
  final out = File(positional[1]);
  out.parent.createSync(recursive: true);

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 60));
    final response = await request.close().timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw StateError('下载失败：HTTP ${response.statusCode}');
    }
    final sink = out.openWrite();
    try {
      await response.pipe(sink);
    } finally {
      await sink.close();
    }
    printLine('saved: ${out.path}');
  } finally {
    client.close(force: true);
  }
}
