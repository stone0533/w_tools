import 'dart:convert';
import 'dart:io';

/// 本月的调用记录。
class UsageEntry {
  UsageEntry({required this.at, required this.kind, required this.cacheFile});

  final String at;
  final String kind;
  final String cacheFile;
}

/// 缓存、令牌与用量记录的读写。
///
/// 路径分三类（都不在项目仓库里）：
/// - 缓存：`~/.cache/w_tools/figma/<项目标识>/`（原 `<project>/.figma-cache/`）
/// - 令牌：`~/.config/w_tools/figma-token`（原 `<project>/.figma-token`）
/// - 额度：`~/.cache/w_tools/figma/_usage.log` / `_budget.json`（按账号，跨项目共用）
///
/// 旧路径由 [migrateLegacy] 一次性搬走。
class CacheStore {
  CacheStore(this.root, {String? home}) : _home = home ?? defaultHome();

  final Directory root;
  final String _home;

  /// 测试用：把 `~` 指到临时目录，避免读真实 `~/.cache/w_tools`。
  static String? homeOverride;

  static String defaultHome() {
    if (homeOverride != null) return homeOverride!;
    final env = Platform.environment;
    return env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
  }

  /// 项目在缓存里的稳定标识：`<目录名>-<hash8>`（FNV-1a，跨进程稳定）。
  String get projectId {
    final path = root.absolute.path;
    var hash = 0x811c9dc5;
    for (final unit in path.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final name = path.split(Platform.pathSeparator).where((e) => e.isNotEmpty).lastOrNull;
    return '${name ?? 'project'}-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// 账号级缓存根（用量 / 预算也在这里）。
  Directory get cacheRoot => Directory('$_home/.cache/w_tools/figma');

  /// 项目缓存目录。
  Directory get dir => Directory('${cacheRoot.path}/$projectId');

  File get tokenFile => File('$_home/.config/w_tools/figma-token');

  File get usageFile => File('${cacheRoot.path}/_usage.log');
  File get budgetFile => File('${cacheRoot.path}/_budget.json');

  /// 旧路径（只用于迁移）。
  Directory get legacyDir => Directory('${root.path}/.figma-cache');
  File get legacyTokenFile => File('${root.path}/.figma-token');

  /// 把旧路径搬到新位置；返回人读的迁移说明（空列表 = 无需迁移）。
  List<String> migrateLegacy() {
    final notes = <String>[];
    if (legacyDir.existsSync()) {
      dir.createSync(recursive: true);
      var moved = 0;
      for (final entity in legacyDir.listSync()) {
        if (entity is! File) continue;
        final target = File('${dir.path}/${entity.uri.pathSegments.last}');
        if (target.existsSync()) continue;
        entity.renameSync(target.path);
        moved++;
      }
      legacyDir.deleteSync(recursive: true);
      if (moved > 0) notes.add('已把 $moved 个缓存文件迁到 ${dir.path}');
    }
    if (legacyTokenFile.existsSync() && !tokenFile.existsSync()) {
      tokenFile.parent.createSync(recursive: true);
      legacyTokenFile.renameSync(tokenFile.path);
      _restrict(tokenFile);
      notes.add('已把 .figma-token 迁到 ${tokenFile.path}');
    }
    return notes;
  }

  static void _restrict(File file) {
    if (Platform.isWindows) return;
    try {
      Process.runSync('chmod', ['600', file.path]);
    } on ProcessException {
      // 权限收紧失败不影响功能
    }
  }

  /// 缓存文件名：`<kind>-<fileKey>-<idslug>[-s<scale>].json`。
  File cacheFile({
    required String kind,
    required String fileKey,
    String? ids,
    int? scale,
    int? depth,
  }) {
    final slug = ids == null ? '' : '-${ids.replaceAll(RegExp(r'[:,.]'), '-')}';
    final suffix = depth != null
        ? '-d$depth'
        : scale == null
            ? ''
            : '-s$scale';
    return File('${dir.path}/$kind-$fileKey$slug$suffix.json');
  }

  /// 记录文件版本的小文件（Tier 3 的 `file/meta` 结果）。
  File metaFile(String fileKey) => File('${dir.path}/_meta-$fileKey.json');

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
    dir.createSync(recursive: true);
    final ts = (now ?? DateTime.now()).toIso8601String();
    usageFile.writeAsStringSync('$ts\t$kind\t$cacheFile\n', mode: FileMode.append);
  }

  /// 本月调用次数（按时间前缀匹配 `yyyy-MM`）。
  int usageCountThisMonth({DateTime? now}) {
    final month = _monthKey(now ?? DateTime.now());
    return usageEntries().where((e) => e.at.startsWith(month)).length;
  }

  List<UsageEntry> usageEntries() {
    if (!usageFile.existsSync()) return const [];
    return usageFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).map((line) {
      final parts = line.split('\t');
      return UsageEntry(
        at: parts.isNotEmpty ? parts[0] : '',
        kind: parts.length > 1 ? parts[1] : '',
        cacheFile: parts.length > 2 ? parts[2] : '',
      );
    }).toList();
  }

  /// 预算配置（`{"limit": 20}`），未配置时默认 20。
  int budgetLimit() {
    final json = read(budgetFile);
    final limit = json?['limit'];
    return limit is int && limit > 0 ? limit : 20;
  }

  String _monthKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}
