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
  });

  final List<String> positional;
  final bool json;
  final String root;
  final String? file;
  final int min;
  final String? out;
  final int depth;
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
}

CliOptions parseOptions(List<String> args) {
  final positional = <String>[];
  var json = false;
  var root = Directory.current.path;
  String? file;
  var min = 1;
  String? out;
  var depth = 3;
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
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--json') {
      json = true;
    } else if (arg.startsWith('--root=')) {
      root = arg.substring('--root='.length);
    } else if (arg.startsWith('--file=')) {
      file = arg.substring('--file='.length);
    } else if (arg.startsWith('--min=')) {
      min = _positiveInt('--min', arg.substring('--min='.length));
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else if (arg.startsWith('--depth=')) {
      depth = _positiveInt('--depth', arg.substring('--depth='.length));
    } else if (arg.startsWith('--scale=')) {
      scale = _positiveInt('--scale', arg.substring('--scale='.length));
    } else if (arg.startsWith('--node-depth=')) {
      nodeDepth = _nonNegativeInt('--node-depth', arg.substring('--node-depth='.length));
    } else if (arg == '--refresh') {
      refresh = true;
    } else if (arg == '--no-log') {
      log = false;
    } else if (arg == '--force') {
      force = true;
    } else if (arg == '--set' || arg.startsWith('--set=')) {
      final raw = arg == '--set'
          ? (i + 1 < args.length ? args[++i] : null)
          : arg.substring('--set='.length);
      if (raw == null || raw.isEmpty) {
        throw const FormatException('--set 需要正整数');
      }
      budgetSet = _positiveInt('--set', raw);
    } else if (arg == '--check-stale') {
      checkStale = true;
    } else if (arg == '--if-stale') {
      ifStale = true;
    } else if (arg == '--node-only') {
      nodeOnly = true;
    } else if (arg.startsWith('--map=')) {
      mapFile = arg.substring('--map='.length);
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
  );
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
