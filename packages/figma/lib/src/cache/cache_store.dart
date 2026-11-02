import 'dart:convert';
import 'dart:io';

/// 本月的调用记录。
class UsageEntry {
  UsageEntry({required this.at, required this.kind, required this.cacheFile});

  final String at;
  final String kind;
  final String cacheFile;
}

/// `.figma-token` / `.figma-cache/` 的读写与用量记录。
class CacheStore {
  CacheStore(this.root);

  final Directory root;

  Directory get dir => Directory('${root.path}/.figma-cache');
  File get tokenFile => File('${root.path}/.figma-token');
  File get usageFile => File('${dir.path}/_usage.log');
  File get budgetFile => File('${dir.path}/_budget.json');

  /// 缓存文件名：`<kind>-<fileKey>-<idslug>[-s<scale>].json`。
  File cacheFile({
    required String kind,
    required String fileKey,
    String? ids,
    int? scale,
  }) {
    final slug = ids == null ? '' : '-${ids.replaceAll(RegExp(r'[:,.]'), '-')}';
    final suffix = scale == null ? '' : '-s$scale';
    return File('${dir.path}/$kind-$fileKey$slug$suffix.json');
  }

  /// 记录文件版本的小文件（Tier 3 的 `file/meta` 结果）。
  File metaFile(String fileKey) => File('${dir.path}/_meta-$fileKey.json');

  /// 读缓存；不存在返回 null。
  Map<String, dynamic>? read(File file) {
    if (!file.existsSync()) return null;
    final raw = jsonDecode(file.readAsStringSync());
    return raw is Map<String, dynamic> ? raw : null;
  }

  /// 写缓存（自动建目录）。
  void write(File file, Map<String, dynamic> json) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
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

  int monthLimitDefault() => 20;

  String _monthKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}
