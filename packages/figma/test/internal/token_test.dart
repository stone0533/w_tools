import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';
import 'package:w_tools_figma/src/cli/token_source.dart';
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

  test('保留模板的 # 注释时只取第一条有效 token 行', () {
    final store = CacheStore(root, home: root.path);
    store.tokenFile.parent.createSync(recursive: true);
    store.tokenFile.writeAsStringSync(
      '# Figma 个人访问令牌\n'
      '# 1. Figma → Settings → Security\n'
      '# 2. 只读权限即可\n'
      'figd_real_token\n',
    );
    expect(readToken(store), 'figd_real_token');
  });

  test('只有注释 / 空文件时报模板内容', () {
    final store = CacheStore(root, home: root.path);
    store.tokenFile.parent.createSync(recursive: true);
    store.tokenFile.writeAsStringSync('# 只有说明\n\n');
    expect(
      () => readToken(store),
      throwsA(isA<FigmaTokenException>().having((e) => e.message, 'message', contains('模板内容'))),
    );
  });
}

/// 测试里只需要 tokenFile；直接用 CacheStore 的根目录。
class CacheStoreForTest extends CacheStore {
  CacheStoreForTest(super.root);
}
