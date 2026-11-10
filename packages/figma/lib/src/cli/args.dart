import 'dart:io';

import 'package:args/args.dart';

/// 项目根默认值：`--root` 未给时用当前目录。
String defaultRoot() => Directory.current.path;

/// 取 `--root=<dir>` / `--root <dir>`；给 `run.dart` 这类需要提前知道 root 的调用方用。
///
/// `parseOptions` 在扫描参数时会自己消费 `--root`，两边共用 [defaultRoot]。
String rootOption(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--root=')) return arg.substring('--root='.length);
    if (arg == '--root' && i + 1 < args.length) return args[i + 1];
  }
  return defaultRoot();
}

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
    required this.ignoreBudget,
    required this.nodeOnly,
    required this.mapFile,
    required this.all,
    required this.yes,
    required this.nameFilter,
    required this.pageFilter,
    required this.verbose,
    required this.seen,
    required this.seenText,
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

  /// `--ignore-budget`：本月额度已尽时仍然请求。
  final bool ignoreBudget;
  final bool nodeOnly;
  final String? mapFile;
  final bool all;

  /// `--yes`：确认破坏性操作（如 cache clean --all）。
  final bool yes;
  final String? nameFilter;
  final String? pageFilter;
  final bool verbose;

  /// 出现过的选项（规范名，供 `rejectUnsupported` 的 allow-list 用）。
  final Set<String> seen;

  /// 规范名 → 命令行上的写法（用于把不支持的选项原样报回去）。
  final Map<String, String> seenText;
}

/// 取值型选项：缺值时也要报中文，别让 ArgParser 抛英文。
const Set<String> _valueOptions = <String>{
  '--root',
  '--file',
  '--min',
  '--out',
  '--depth',
  '--scale',
  '--node-depth',
  '--set',
  '--name',
  '--page',
  '--map',
};

ArgParser _buildParser() {
  return ArgParser()
    ..addFlag('json', negatable: false)
    ..addOption('root')
    ..addOption('file')
    ..addOption('min')
    ..addOption('out')
    ..addOption('depth')
    ..addOption('scale')
    ..addOption('node-depth')
    ..addFlag('refresh', negatable: false)
    ..addFlag('no-log', negatable: false)
    ..addFlag('force', negatable: false)
    ..addOption('set')
    ..addFlag('check-stale', negatable: false)
    ..addFlag('if-stale', negatable: false)
    ..addFlag('ignore-budget', negatable: false)
    ..addFlag('node-only', negatable: false)
    ..addFlag('all', negatable: false)
    ..addFlag('yes', abbr: 'y', negatable: false)
    ..addOption('name')
    ..addOption('page')
    ..addFlag('verbose', negatable: false)
    ..addOption('map');
}

/// 未知选项保留中文报错（ArgParser 自己的消息是英文）。
void _rejectUnknownFlags(List<String> args, ArgParser parser) {
  for (final arg in args) {
    if (arg == '--' || arg == '-' || !arg.startsWith('-')) continue;
    final name = arg.startsWith('--')
        ? arg.substring(2).split('=').first
        : arg.substring(1).split('=').first;
    if (name == 'h' || name == 'y') continue;
    final option = parser.options[name];
    if (option == null) {
      throw FormatException('未知选项：${arg.split('=').first}');
    }
    // 布尔 flag 不接受 `=值`：旧解析器把 `--json=true` 当未知选项，保持这条。
    if (option.isFlag && arg.contains('=')) {
      throw FormatException('未知选项：$arg');
    }
  }
}

/// 取值型选项写到末尾但没给值：`--depth`。
void _rejectMissingValues(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (_valueOptions.contains(args[i]) && i + 1 >= args.length) {
      throw FormatException('${args[i]} 需要一个值');
    }
  }
}

CliOptions parseOptions(List<String> args) {
  final parser = _buildParser();
  _rejectUnknownFlags(args, parser);
  _rejectMissingValues(args);

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on ArgParserException catch (e) {
    throw FormatException('参数解析失败：${e.message}');
  }

  int? intOf(String name, String flag, {required bool positive}) {
    final raw = results[name] as String?;
    if (raw == null) return null;
    return positive ? _positiveInt(flag, raw) : _nonNegativeInt(flag, raw);
  }

  final seen = <String>{};
  final seenText = <String, String>{};
  for (final name in parser.options.keys) {
    if (!results.wasParsed(name)) continue;
    seen.add(name);
    seenText.putIfAbsent(name, () => '--$name');
  }

  return CliOptions(
    positional: results.rest,
    json: results['json'] as bool,
    root: (results['root'] as String?) ?? defaultRoot(),
    file: results['file'] as String?,
    min: intOf('min', '--min', positive: true) ?? 1,
    out: results['out'] as String?,
    depth: intOf('depth', '--depth', positive: true),
    scale: intOf('scale', '--scale', positive: true) ?? 2,
    nodeDepth: intOf('node-depth', '--node-depth', positive: false),
    refresh: results['refresh'] as bool,
    log: !(results['no-log'] as bool),
    budgetSet: intOf('set', '--set', positive: true),
    checkStale: results['check-stale'] as bool,
    force: results['force'] as bool,
    ifStale: results['if-stale'] as bool,
    ignoreBudget: results['ignore-budget'] as bool,
    nodeOnly: results['node-only'] as bool,
    mapFile: results['map'] as String?,
    all: results['all'] as bool,
    yes: results['yes'] as bool,
    nameFilter: results['name'] as String?,
    pageFilter: results['page'] as String?,
    verbose: results['verbose'] as bool,
    seen: seen,
    seenText: seenText,
  );
}

/// 拒绝当前命令不支持的显式选项，避免 --min 被 spec 静默忽略。
void rejectUnsupported(CliOptions options, Set<String> allowed) {
  final bad = options.seen.difference(allowed);
  if (bad.isEmpty) return;
  final names = bad.map((e) => options.seenText[e] ?? '--$e').toList()..sort();
  throw FormatException('不支持的选项：${names.join(', ')}');
}

/// 位置参数超出上限就报错：多写的参数以前会被静默忽略（`spec 1:2 9:9` 只处理第一个）。
void rejectExtraPositional(CliOptions options, int max) {
  if (options.positional.length <= max) return;
  final extra = options.positional.sublist(max);
  throw FormatException('多余的参数：${extra.join(' ')}');
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
