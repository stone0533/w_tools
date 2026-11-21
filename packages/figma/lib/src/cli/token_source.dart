import 'dart:io';

import '../cache/cache_store.dart';
import 'cli_io.dart';

export '../spec/cache_document.dart' show readDocument, readDocuments;

String readToken(CacheStore store, {String? envToken}) {
  // CI / agent 优先用环境变量，避免把 token 写进项目目录。
  final fromEnv = (envToken ?? Platform.environment['FIGMA_TOKEN'] ?? '').trim();
  if (fromEnv.isNotEmpty) {
    return _validateToken(fromEnv, 'FIGMA_TOKEN');
  }

  final file = store.tokenFile;
  if (!file.existsSync()) {
    throw FigmaTokenException('缺少 ${file.path} 或 FIGMA_TOKEN，先跑 init 并填入 figd_ 令牌');
  }
  final token = tokenLineOf(file.readAsStringSync());
  if (token.isEmpty || token.contains('REPLACE_ME')) {
    throw FigmaTokenException('${file.path} 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  return _validateToken(token, file.path);
}

/// 取 token 文件里第一条有效行：允许保留 `init` 生成的 `#` 说明注释和空行。
///
/// 整个文件 `trim()` 后校验会把注释也算进 token，导致按模板填写后必然失败；
/// 读取时只取第一条非空、非注释行。
String tokenLineOf(String content) {
  for (final line in content.split(RegExp(r'\r?\n'))) {
    final value = line.trim();
    if (value.isEmpty || value.startsWith('#')) continue;
    return value;
  }
  return '';
}

String _validateToken(String token, String source) {
  if (token.contains('REPLACE_ME') || token.isEmpty) {
    throw FigmaTokenException('$source 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  if (!token.startsWith('figd_')) {
    throw FigmaTokenException('$source 里的 token 需要 figd_ 开头');
  }
  return token;
}
