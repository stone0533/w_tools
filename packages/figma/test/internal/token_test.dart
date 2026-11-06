import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';
import 'package:w_tools_figma/src/cli/cache_data.dart';
import 'package:w_tools_figma/src/cli/cli_io.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_token_');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('FIGMA_TOKEN 优先于 .figma-token', () {
    final token = readToken(CacheStoreForTest(root), envToken: 'figd_env');
    expect(token, 'figd_env');
  });

  test('环境变量不是 figd_ 时报错', () {
    expect(
      () => readToken(CacheStoreForTest(root), envToken: 'bad'),
      throwsA(isA<FigmaTokenException>()),
    );
  });
}

/// 测试里只需要 tokenFile；直接用 CacheStore 的根目录。
class CacheStoreForTest extends CacheStore {
  CacheStoreForTest(super.root);
}
