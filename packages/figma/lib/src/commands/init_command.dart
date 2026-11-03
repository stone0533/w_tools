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
# 3. 这个文件在用户配置目录（~/.config/w_tools/），权限 600，不要提交/外传
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

    // 新路径都在仓库外；只有老项目还留着旧文件时才补 .gitignore，避免误提交。
    final added = <String>[];
    final gitignore = File('${store.root.path}/.gitignore');
    final existing = gitignore.existsSync() ? gitignore.readAsStringSync() : '';
    final lines = existing.split('\n');
    final legacy = <String>[
      if (store.legacyTokenFile.existsSync()) '.figma-token',
      if (store.legacyDir.existsSync()) '.figma-cache/',
    ];
    for (final entry in legacy) {
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
