import 'dart:io';

import 'args.dart';
import 'cli_io.dart';

/// 下载 fetch images 返回的签名 URL；不访问 Figma API，不消耗额度。
Future<void> runGet(List<String> args) async {
  final options = parseCommand(args, 'get');

  rejectExtra(options, 2);
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
  // 尾斜杠表示调用方想给一个目录；即使目录还不存在，也不能把它当文件写。
  final looksLikeDirectory = out.path.endsWith('/') ||
      out.path.endsWith(Platform.pathSeparator) ||
      out.path.endsWith('\\');
  if (looksLikeDirectory || FileSystemEntity.isDirectorySync(out.path)) {
    throw StateError('输出路径是目录：${out.path}');
  }
  out.parent.createSync(recursive: true);

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 60));
    final response = await request.close().timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw StateError('下载失败：HTTP ${response.statusCode}（$rawUrl）');
    }
    final temp = File('${out.path}.tmp');
    if (temp.existsSync()) temp.deleteSync();
    final sink = temp.openWrite();
    try {
      await response.timeout(const Duration(seconds: 120)).pipe(sink);
      await sink.close();
      if (out.existsSync()) out.deleteSync();
      temp.renameSync(out.path);
    } catch (_) {
      if (temp.existsSync()) temp.deleteSync();
      rethrow;
    }
    printLine('saved: ${out.path}');
  } finally {
    client.close(force: true);
  }
}
