import 'dart:convert';
import 'dart:io';

import '../cache/cache_store.dart';

/// `init` 的结果。
class InitResult {
  InitResult({
    required this.tokenCreated,
    required this.gitignoreAdded,
    required this.cacheDir,
  });

  final bool tokenCreated;
  final List<String> gitignoreAdded;
  final Directory cacheDir;
}

/// 初始化项目：建 token 模板、补 `.gitignore`、建缓存目录与预算文件。
class InitCommand {
  InitCommand(this.store);

  final CacheStore store;

  static const _tokenTemplate = '''
# Figma 个人访问令牌（figd_ 开头）
# 1. Figma → Settings → Security → Personal access tokens → 生成
# 2. 只读权限即可（本工具只调用 GET 接口）
# 3. 该文件已在 .gitignore 里，不要提交
figd_REPLACE_ME
''';

  InitResult run({bool force = false}) {
    var tokenCreated = false;
    final token = store.tokenFile;
    if (!token.existsSync() || force) {
      token.parent.createSync(recursive: true);
      token.writeAsStringSync(_tokenTemplate);
      _restrictTokenPermissions(token);
      tokenCreated = true;
    }

    final added = <String>[];
    final gitignore = File('${store.root.path}/.gitignore');
    final existing = gitignore.existsSync() ? gitignore.readAsStringSync() : '';
    final lines = existing.split('\n');
    for (final entry in const ['.figma-token', '.figma-cache/']) {
      if (!lines.contains(entry)) added.add(entry);
    }
    if (added.isNotEmpty) {
      final buffer = StringBuffer(existing);
      if (existing.isNotEmpty && !existing.endsWith('\n')) buffer.writeln();
      buffer.writeln(added.join('\n'));
      gitignore.writeAsStringSync(buffer.toString());
    }

    store.dir.createSync(recursive: true);
    if (!store.budgetFile.existsSync()) {
      store.budgetFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'limit': 20, 'month': ''}),
      );
    }
    return InitResult(
      tokenCreated: tokenCreated,
      gitignoreAdded: added,
      cacheDir: store.dir,
    );
  }

  void _restrictTokenPermissions(File token) {
    if (Platform.isWindows) return;
    try {
      Process.runSync('chmod', <String>['600', token.path]);
    } on ProcessException {
      // 无 chmod 的环境不阻塞 init；.gitignore 仍然保护 token 不被提交。
    }
  }
}
