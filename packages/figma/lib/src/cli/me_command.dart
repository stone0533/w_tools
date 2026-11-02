import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import 'args.dart';
import 'cache_data.dart';
import 'cli_io.dart';

/// 校验 token，打印当前 Figma 用户。
Future<void> runMe(List<String> args) async {
  final options = parseOptions(args);
  final store = CacheStore(Directory(options.root));
  final client = HttpFigmaClient(token: readToken(store));
  try {
    final payload = await client.getJson(Uri.parse('https://api.figma.com/v1/me'));
    if (options.json) {
      printLine(jsonEncode(payload));
      return;
    }
    final handle = payload['handle'] ?? payload['email'] ?? payload['id'] ?? 'unknown';
    printLine('token ok: $handle');
  } finally {
    client.close();
  }
}
