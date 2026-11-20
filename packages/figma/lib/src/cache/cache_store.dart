import 'dart:convert';
import 'dart:io';

import 'cache_paths.dart';
import 'usage_log.dart';

export 'usage_log.dart' show UsageEntry;

/// 缓存、令牌与用量记录的读写。
///
/// 路径分三类（都不在项目仓库里）：
/// - 缓存：`~/.cache/w_tools/figma/<项目标识>/`
/// - 令牌：`~/.config/w_tools/figma-token`
/// - 额度：`~/.cache/w_tools/figma/_usage.log` / `_budget.json`（按账号，跨项目共用）
///
/// 路径解析在 [CachePaths]，用量 / 预算在 [UsageLog]；这里只保留文件读写门面。
class CacheStore {
  CacheStore(
    this.root, {
    String? home,
    bool? windows,
    Map<String, String>? environment,
  }) : _paths = CachePaths(
          root,
          home: home ?? CachePaths.defaultHome(),
          windows: windows,
          environment: environment,
        );

  final Directory root;
  final CachePaths _paths;
  late final UsageLog _usage = UsageLog(_paths);

  static String defaultHome() => CachePaths.defaultHome();

  String get projectId => _paths.projectId;
  Directory get cacheRoot => _paths.cacheRoot;
  Directory get dir => _paths.dir;
  File get tokenFile => _paths.tokenFile;
  File get usageFile => _paths.usageFile;
  File get budgetFile => _paths.budgetFile;

  /// 缓存文件名：`<kind>-<fileKey>-<idslug>[-s<scale>].json`。
  File cacheFile({
    required String kind,
    required String fileKey,
    String? ids,
    int? scale,
    int? depth,
  }) =>
      _paths.cacheFile(kind: kind, fileKey: fileKey, ids: ids, scale: scale, depth: depth);

  /// 记录文件版本的小文件（Tier 3 的 `file/meta` 结果）。
  File metaFile(String fileKey) => _paths.metaFile(fileKey);

  /// 读缓存；不存在返回 null。
  Map<String, dynamic>? read(File file) {
    if (!file.existsSync()) return null;
    try {
      final raw = jsonDecode(file.readAsStringSync());
      return raw is Map<String, dynamic> ? raw : null;
    } on FormatException {
      // 损坏的缓存当作未命中，避免 CLI 直接崩在 JSON 解析上。
      return null;
    }
  }

  /// 写缓存（自动建目录）。
  void write(File file, Map<String, dynamic> json) {
    file.parent.createSync(recursive: true);
    final encoded = const JsonEncoder.withIndent('  ').convert(json);
    final temp = File('${file.path}.tmp');
    temp.writeAsStringSync(encoded);
    try {
      temp.renameSync(file.path);
    } on FileSystemException {
      // Windows 上目标存在时 rename 可能失败；退回直接覆盖。
      file.writeAsStringSync(encoded);
      if (temp.existsSync()) temp.deleteSync();
    }
  }

  /// 追加一条用量记录（只在真的打了接口时调用）。
  void logUsage({required String kind, required String cacheFile, DateTime? now}) {
    _usage.logUsage(kind: kind, cacheFile: cacheFile, now: now);
  }

  List<UsageEntry> usageEntries() => _usage.entries();

  /// 预算配置（`{"limit": 20}`），未配置时默认 20。
  int budgetLimit() => _usage.budgetLimit();
}
