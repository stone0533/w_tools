import 'dart:io';

class CliOptions {
  CliOptions({
    required this.positional,
    required this.json,
    required this.root,
    required this.file,
    required this.min,
    required this.out,
    required this.depth,
    required this.scale,
    required this.nodeDepth,
    required this.refresh,
    required this.log,
    required this.budgetSet,
    required this.checkStale,
    required this.force,
    required this.ifStale,
    required this.nodeOnly,
    required this.mapFile,
    required this.all,
    required this.yes,
    required this.nameFilter,
    required this.pageFilter,
    required this.verbose,
    required this.seen,
  });

  final List<String> positional;
  final bool json;
  final String root;
  final String? file;
  final int min;
  final String? out;

  /// `--depth`：不传时 `fetch file` 用 3，`fetch nodes` 不带 depth（保持旧行为）。
  final int? depth;
  final int scale;
  final int? nodeDepth;
  final bool refresh;
  final bool log;
  final int? budgetSet;
  final bool checkStale;
  final bool force;
  final bool ifStale;
  final bool nodeOnly;
  final String? mapFile;
  final bool all;

  /// `--yes`：确认破坏性操作（如 cache clean --all）。
  final bool yes;
  final String? nameFilter;
  final String? pageFilter;
  final bool verbose;
  final Set<String> seen;
}

CliOptions parseOptions(List<String> args) {
  final positional = <String>[];
  var json = false;
  var root = Directory.current.path;
  String? file;
  var min = 1;
  String? out;
  int? depth;
  var scale = 2;
  int? nodeDepth;
  var refresh = false;
  var log = true;
  int? budgetSet;
  var checkStale = false;
  var force = false;
  var ifStale = false;
  var nodeOnly = false;
  String? mapFile;
  var all = false;
  var yes = false;
  String? nameFilter;
  String? pageFilter;
  var verbose = false;
  final seen = <String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--json') {
      json = true;
      seen.add('json');
    } else if (arg.startsWith('--root=')) {
      root = arg.substring('--root='.length);
      seen.add('root');
    } else if (arg.startsWith('--file=')) {
      file = arg.substring('--file='.length);
      seen.add('file');
    } else if (arg.startsWith('--min=')) {
      min = _positiveInt('--min', arg.substring('--min='.length));
      seen.add('min');
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
      seen.add('out');
    } else if (arg.startsWith('--depth=')) {
      depth = _positiveInt('--depth', arg.substring('--depth='.length));
      seen.add('depth');
    } else if (arg.startsWith('--scale=')) {
      scale = _positiveInt('--scale', arg.substring('--scale='.length));
      seen.add('scale');
    } else if (arg.startsWith('--node-depth=')) {
      nodeDepth = _nonNegativeInt('--node-depth', arg.substring('--node-depth='.length));
      seen.add('node-depth');
    } else if (arg == '--yes' || arg == '-y') {
      yes = true;
      seen.add('yes');
    } else if (arg == '--refresh') {
      refresh = true;
      seen.add('refresh');
    } else if (arg == '--no-log') {
      log = false;
      seen.add('no-log');
    } else if (arg == '--force') {
      force = true;
      seen.add('force');
    } else if (arg == '--set' || arg.startsWith('--set=')) {
      final raw = arg == '--set'
          ? (i + 1 < args.length ? args[++i] : null)
          : arg.substring('--set='.length);
      if (raw == null || raw.isEmpty) {
        throw const FormatException('--set 需要正整数');
      }
      budgetSet = _positiveInt('--set', raw);
      seen.add('set');
    } else if (arg == '--check-stale') {
      checkStale = true;
      seen.add('check-stale');
    } else if (arg == '--if-stale') {
      ifStale = true;
      seen.add('if-stale');
    } else if (arg == '--node-only' || arg == '--no-markdown') {
      nodeOnly = true;
      seen.add('node-only');
    } else if (arg == '--all') {
      all = true;
      seen.add('all');
    } else if (arg.startsWith('--name=')) {
      nameFilter = arg.substring('--name='.length);
      seen.add('name');
    } else if (arg.startsWith('--page=')) {
      pageFilter = arg.substring('--page='.length);
      seen.add('page');
    } else if (arg == '--verbose') {
      verbose = true;
      seen.add('verbose');
    } else if (arg.startsWith('--map=')) {
      mapFile = arg.substring('--map='.length);
      seen.add('map');
    } else if (arg.startsWith('--')) {
      throw FormatException('未知选项：$arg');
    } else {
      positional.add(arg);
    }
  }
  return CliOptions(
    positional: positional,
    json: json,
    root: root,
    file: file,
    min: min,
    out: out,
    depth: depth,
    scale: scale,
    nodeDepth: nodeDepth,
    refresh: refresh,
    log: log,
    budgetSet: budgetSet,
    checkStale: checkStale,
    force: force,
    ifStale: ifStale,
    nodeOnly: nodeOnly,
    mapFile: mapFile,
    all: all,
    yes: yes,
    nameFilter: nameFilter,
    pageFilter: pageFilter,
    verbose: verbose,
    seen: seen,
  );
}

/// 拒绝当前命令不支持的显式选项，避免 --min 被 spec 静默忽略。
void rejectUnsupported(CliOptions options, Set<String> allowed) {
  final bad = options.seen.difference(allowed);
  if (bad.isEmpty) return;
  final names = bad.map((e) => '--$e').toList()..sort();
  throw FormatException('不支持的选项：${names.join(', ')}');
}

int _positiveInt(String option, String raw) {
  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    throw FormatException('$option 需要正整数：$raw');
  }
  return value;
}

int _nonNegativeInt(String option, String raw) {
  final value = int.tryParse(raw);
  if (value == null || value < 0) {
    throw FormatException('$option 需要非负整数：$raw');
  }
  return value;
}
