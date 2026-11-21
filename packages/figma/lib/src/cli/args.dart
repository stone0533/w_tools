import 'dart:io';

import 'package:args/args.dart';

/// 项目根默认值：从当前目录向上找最近的 `.git`（仓库根）或 `pubspec.yaml`；
/// 都找不到时回退当前目录。这样从 `tool/` 等子目录运行仍复用同一个项目缓存。
String defaultRoot() {
  final current = Directory.current.absolute;
  final root = _findAncestor(current, 'pubspec.yaml') ?? _findAncestor(current, '.git') ?? current;
  return root.path;
}

Directory? _findAncestor(Directory start, String marker) {
  var dir = start;
  while (true) {
    if (File('${dir.path}/$marker').existsSync() || Directory('${dir.path}/$marker').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// 解析后的命令参数（每个命令只声明自己支持的选项）。
class CommandArgs {
  CommandArgs(this.results, this._defined);

  final ArgResults results;
  final Set<String> _defined;

  List<String> get positional => results.rest;
  bool wasProvided(String name) => results.wasParsed(name);
  bool flag(String name) => _defined.contains(name) && (results[name] as bool? ?? false);
  String? option(String name) => _defined.contains(name) ? results[name] as String? : null;

  String get root {
    final raw = option('root');
    if (raw == null) return defaultRoot();
    final value = raw.trim();
    if (value.isEmpty) {
      throw const FormatException('--root 需要一个目录，不能为空');
    }
    if (!Directory(value).existsSync()) {
      throw FormatException('--root 目录不存在：$value');
    }
    return value;
  }

  bool get json => flag('json');
  String? get file => option('file');
  int get min => intOption('min') ?? 1;
  String? get out => option('out');
  int? get depth => intOption('depth', positive: false);
  int get scale => intOption('scale') ?? 2;
  int? get nodeDepth => intOption('node-depth', positive: false);
  bool get refresh => flag('refresh');
  int? get budgetSet => intOption('set');
  bool get checkStale => flag('check-stale');
  bool get force => flag('force');
  bool get ifStale => flag('if-stale');
  bool get nodeOnly => flag('node-only');
  String? get mapFile => option('map');
  bool get skipMarkdown => flag('skip-markdown');
  bool get withId => flag('with-id');
  bool get withLayout => flag('with-layout');
  bool get skipHidden => flag('skip-hidden');
  bool get allowDepth => flag('allow-depth');
  int? get limit => intOption('limit');
  String? get skipNamePrefix => option('skip-name-prefix');
  bool get all => flag('all');
  bool get yes => flag('yes');
  bool get files => flag('files');
  bool get legacy => flag('legacy');
  String? get nameFilter => option('name');
  String? get pageFilter => option('page');
  bool get verbose => flag('verbose');

  int? intOption(String name, {bool positive = true}) {
    final raw = option(name);
    if (raw == null) return null;
    final value = int.tryParse(raw);
    if (value == null || (positive ? value <= 0 : value < 0)) {
      throw FormatException('--$name 需要${positive ? '正整数' : '非负整数'}：$raw');
    }
    return value;
  }
}

/// 每个命令只声明自己认识的选项；不再维护全局选项全集 + allow-list。
ArgParser parserFor(String command) {
  final parser = ArgParser();
  switch (command) {
    case 'init':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addFlag('force', negatable: false, help: '只重建模板 token');
    case 'frames':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addOption('file', valueHelp: 'path', help: '直接解析指定 nodes 缓存')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addFlag('all', negatable: false, help: '包含嵌套画板')
        ..addOption('name', help: '按画板名过滤（子串）')
        ..addOption('page', help: '按页面名过滤（子串）')
        ..addOption('depth', valueHelp: 'n', help: '限制嵌套层级（0 = 顶层，隐含 --all）')
        ..addOption('limit', valueHelp: 'n', help: '最多输出 n 条')
        ..addFlag('verbose', negatable: false, help: '显示 cacheFile');
    case 'fetch':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addOption('depth', valueHelp: 'n', help: 'nodes 的深度（不传则不限制）')
        ..addOption('scale', valueHelp: 'n', help: 'images 的倍率（默认 2）')
        ..addFlag('refresh', negatable: false, help: '绕过缓存重新请求（仅 nodes）')
        ..addFlag('check-stale', negatable: false, help: '用 /meta 检查缓存版本（仅 nodes）');
    case 'usage':
      parser
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addOption('set', valueHelp: 'n', help: '设置月度预算');
    case 'cache':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addFlag('all', negatable: false, help: '清理所有项目缓存')
        ..addFlag('yes', abbr: 'y', negatable: false, help: '确认破坏性操作')
        ..addFlag('files', negatable: false, help: 'stats 列出每个缓存文件')
        ..addFlag('legacy', negatable: false, help: 'clean 只删旧 file-* 缓存')
        ..addOption('file', valueHelp: 'path', help: 'clean 只删指定缓存文件');
    case 'diff':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addFlag('if-stale', negatable: false, help: '版本没变就跳过请求');
    case 'get':
      break;
    case 'me':
      parser.addFlag('json', negatable: false, help: '输出 JSON');
    case 'url':
      parser.addFlag('json', negatable: false, help: '输出 JSON');
    case 'spec':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addOption('file', valueHelp: 'path', help: '指定缓存节点树 JSON')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addFlag('node-only', negatable: false, help: '只输出 node，不带 markdown')
        ..addOption('node-depth', valueHelp: 'n', help: '限制 node 子节点深度（0 = 不带 children）')
        ..addOption('skip-name-prefix', valueHelp: 's', help: '跳过名称以该前缀开头的节点（逗号分隔）')
        ..addFlag('with-id', negatable: false, help: 'markdown 表格加 nodeId 列')
        ..addFlag('with-layout', negatable: false, help: 'markdown 表格加布局列')
        ..addFlag('skip-hidden',
            negatable: false, help: '跳过 visible=false / opacity=0 的节点（node 与 markdown 同步）')
        ..addFlag('allow-depth', negatable: false, help: '允许读取最新的 --depth 裁剪缓存（默认优先完整树）');
    case 'tokens':
      parser
        ..addOption('root', valueHelp: 'dir', help: '项目根（默认向上找 .git / pubspec）')
        ..addOption('file', valueHelp: 'path', help: '指定缓存节点树 JSON')
        ..addFlag('json', negatable: false, help: '输出 JSON')
        ..addOption('min', valueHelp: 'n', help: '只列出出现次数 >= n 的项')
        ..addOption('out', valueHelp: 'path', help: '写入文件（默认 stdout）')
        ..addOption('map', valueHelp: 'path', help: '颜色语义映射 YAML')
        ..addOption('skip-name-prefix', valueHelp: 's', help: '跳过名称以该前缀开头的节点（逗号分隔）')
        ..addFlag('allow-depth', negatable: false, help: '允许读取最新的 --depth 裁剪缓存（默认优先完整树）')
        ..addFlag('skip-markdown', negatable: false, help: '只输出结构化数组');
    default:
      throw FormatException('未知命令：$command');
  }
  return parser;
}

CommandArgs parseCommand(List<String> args, String command) {
  final parser = parserFor(command);
  _rejectUnknownFlags(args, parser);
  _rejectMissingValues(args, parser);

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on ArgParserException catch (e) {
    throw FormatException('参数解析失败：${e.message}');
  }
  return CommandArgs(results, parser.options.keys.toSet());
}

/// 解析逗号分隔的 nodeId：trim、去空、保序去重。
///
/// `tokens 1:1,1:1` 以前会把同一棵子树统计两遍；`fetch` 早已去重，这里统一口径。
List<String> parseNodeIds(String? raw) {
  final ids = <String>[];
  for (final part in (raw ?? '').split(',')) {
    final id = part.trim();
    if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

/// 位置参数超出上限就报错：多写的参数以前会被静默忽略（`spec 1:2 9:9` 只处理第一个）。
void rejectExtra(CommandArgs args, int max) {
  if (args.positional.length <= max) return;
  final extra = args.positional.sublist(max);
  throw FormatException('多余的参数：${extra.join(' ')}');
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
void _rejectMissingValues(List<String> args, ArgParser parser) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--') || arg.contains('=')) continue;
    final option = parser.options[arg.substring(2)];
    if (option != null && !option.isFlag && i + 1 >= args.length) {
      throw FormatException('$arg 需要一个值');
    }
  }
}
