import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';
import 'args.dart';

const _tokenTemplate = '''
# Figma 个人访问令牌（figd_ 开头）
# 1. Figma → Settings → Security → Personal access tokens → 生成
# 2. 只读权限即可（本工具只调用 GET 接口）
# 3. 这个文件在用户配置目录（~/.config/w_tools/），权限 600，不要提交/外传
figd_REPLACE_ME
''';

void runInit(List<String> args) {
  final options = parseCommand(args, 'init');

  rejectExtra(options, 0);
  final store = CacheStore(Directory(options.root));
  final result = initProject(store, force: options.force);
  stderr.writeln(
    result.tokenCreated
        ? '已创建 ${store.tokenFile.path}（记得填入 figd_ 令牌）'
        : '${store.tokenFile.path} 已存在',
  );
  stderr.writeln('缓存目录：${result.cacheDir.path}');
}

/// 初始化：建 token 模板、缓存目录与预算文件。
({bool tokenCreated, Directory cacheDir}) initProject(
  CacheStore store, {
  bool force = false,
}) {
  var tokenCreated = false;
  final token = store.tokenFile;
  final existingToken = token.existsSync() ? token.readAsStringSync() : null;
  final isTemplate =
      existingToken == null || existingToken.trim().isEmpty || existingToken.contains('REPLACE_ME');
  if (existingToken == null || (force && isTemplate)) {
    token.parent.createSync(recursive: true);
    token.writeAsStringSync(_tokenTemplate);
    _restrictTokenPermissions(token);
    tokenCreated = true;
  } else if (force && !isTemplate) {
    // --force 只重建模板，不能把真实凭证覆盖成占位符。
    throw StateError(
      '${token.path} 已有真实 token，--force 不会覆盖；确认要重建时先手动删除该文件',
    );
  }

  store.dir.createSync(recursive: true);
  if (!store.budgetFile.existsSync()) {
    store.budgetFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'limit': 20}),
    );
  }
  return (tokenCreated: tokenCreated, cacheDir: store.dir);
}

void _restrictTokenPermissions(File token) {
  if (Platform.isWindows) return;
  try {
    Process.runSync('chmod', <String>['600', token.path]);
  } on ProcessException {
    // 无 chmod 的环境不阻塞 init。
  }
}
