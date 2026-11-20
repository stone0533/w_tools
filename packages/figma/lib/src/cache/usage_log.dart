import 'dart:convert';
import 'dart:io';

import 'cache_paths.dart';

/// 本月的调用记录。
class UsageEntry {
  UsageEntry({required this.at, required this.kind, required this.cacheFile});

  final String at;
  final String kind;
  final String cacheFile;
}

/// `_usage.log` / `_budget.json` 的读写。
class UsageLog {
  UsageLog(this.paths);

  final CachePaths paths;

  File get file => paths.usageFile;

  /// 追加一条用量记录（只在真的打了接口时调用）。
  void logUsage({required String kind, required String cacheFile, DateTime? now}) {
    paths.dir.createSync(recursive: true);
    final ts = (now ?? DateTime.now()).toIso8601String();
    file.writeAsStringSync('$ts\t$kind\t$cacheFile\n', mode: FileMode.append);
  }

  List<UsageEntry> entries() {
    if (!file.existsSync()) return const [];
    return file.readAsLinesSync().where((l) => l.trim().isNotEmpty).map((line) {
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
    final budget = paths.budgetFile;
    if (!budget.existsSync()) return 20;
    try {
      final raw = jsonDecode(budget.readAsStringSync());
      final limit = raw is Map ? raw['limit'] : null;
      return limit is int && limit > 0 ? limit : 20;
    } on FormatException {
      return 20;
    }
  }
}
