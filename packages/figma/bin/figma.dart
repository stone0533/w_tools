import 'dart:convert';
import 'dart:io';

import 'package:w_tools_figma/w_tools_figma.dart';

const _usage = '''
w_tools_figma — 只读的 Figma 取数与规格导出 CLI（契约见 docs/figma-cli.md）

用法：
  dart run w_tools_figma:figma spec   <nodeId> [选项]
  dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [选项]

选项（spec / tokens 通用）：
  --file=<path>   指定缓存节点树 JSON（默认取 .figma-cache/nodes-*.json 中最大的一个）
  --root=<dir>    项目根（默认当前目录），用于定位 .figma-cache/
  --json          输出 JSON（默认输出 Markdown）
  -h, --help      显示帮助

tokens 专属：
  --min=<n>       只列出出现次数 >= n 的项（默认 1）
  --out=<path>    写入文件（默认打印到 stdout）

说明：
  · 本命令只读本地缓存，不访问 Figma，不消耗额度；
  · 缓存由 `dart run w_tools_figma:figma fetch nodes ...`（待实现）或项目脚本生成。
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.write(_usage);
    exitCode = args.isEmpty ? 2 : 0;
    return;
  }

  final command = args.first;
  final rest = args.sublist(1);
  try {
    switch (command) {
      case 'spec':
        await _runSpec(rest);
      case 'tokens':
        await _runTokens(rest);
      case 'version':
        stdout.writeln('w_tools_figma 0.1.0');
      default:
        stderr.writeln('未知命令：$command\n');
        stdout.write(_usage);
        exitCode = 2;
    }
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  } on FileSystemException catch (e) {
    stderr.writeln('读取失败：${e.message}（${e.path}）');
    exitCode = 1;
  }
}

Future<void> _runTokens(List<String> args) async {
  final options = _parseOptions(args);
  final rawIds = options.positional.isEmpty ? null : options.positional.first;
  if (rawIds == null) {
    stderr.writeln('tokens 需要节点 id，例如：tokens 1862:9222,1862:9226');
    exitCode = 2;
    return;
  }
  final nodeIds = rawIds.split(',').where((e) => e.isNotEmpty).toList();

  final file =
      options.file != null ? File(options.file!) : _pickLargestCache(Directory(options.root));
  final document = _documentOf(file);

  final collector = TokenCollector(minCount: options.min);
  final missing = <String>[];
  for (final id in nodeIds) {
    final node = findFigmaNode(document, id);
    if (node == null) {
      missing.add(id);
      continue;
    }
    collector.collect(node);
  }
  if (missing.isNotEmpty) {
    throw StateError('在缓存里找不到节点：${missing.join(', ')}');
  }

  final markdown = const TokensRenderer().renderMarkdown(
    tokens: collector,
    source: file.path,
    nodeIds: nodeIds,
  );
  if (options.out != null) {
    File(options.out!).writeAsStringSync(markdown);
    stderr.writeln('已写入 ${options.out}');
    return;
  }
  if (options.json) {
    stdout.writeln(
      jsonEncode({
        'schema': 'w_tools_figma.tokens/1',
        'source': file.path,
        'nodeIds': nodeIds,
        'counts': {
          'colors': collector.colorsSorted().length,
          'texts': collector.textsSorted().length,
          'radii': collector.radiiSorted().length,
          'spacings': collector.spacingsSorted().length,
        },
        'markdown': markdown,
      }),
    );
    return;
  }
  stdout.write(markdown);
}

Future<void> _runSpec(List<String> args) async {
  final options = _parseOptions(args);
  final nodeId = options.positional.isEmpty ? null : options.positional.first;
  if (nodeId == null) {
    stderr.writeln('spec 需要 nodeId，例如：spec 1862:9222');
    exitCode = 2;
    return;
  }

  final root = Directory(options.root);
  final file = options.file != null ? File(options.file!) : _pickLargestCache(root);

  final document = _documentOf(file);

  const renderer = FigmaSpecRenderer();
  if (options.json) {
    final markdown = renderer.renderMarkdownFromRoot(document, nodeId);
    stdout.writeln(
      jsonEncode({
        'schema': 'w_tools_figma.spec/1',
        'source': file.path,
        'nodeId': nodeId,
        'markdown': markdown,
      }),
    );
    return;
  }
  stderr.writeln('> 数据源：${file.path}');
  stdout.write(renderer.renderMarkdownFromRoot(document, nodeId));
}

File _pickLargestCache(Directory root) {
  final dir = Directory('${root.path}/.figma-cache');
  if (!dir.existsSync()) {
    throw StateError('找不到 ${dir.path}，先拉一次节点树缓存');
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.split('/').last.startsWith('nodes-'))
      .toList()
    ..sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
  if (files.isEmpty) {
    throw StateError('${dir.path} 里没有 nodes-*.json，先拉一次节点树缓存');
  }
  return files.first;
}

/// 读取 nodes 缓存 → 第一个节点的 `document` 子树。
Map<String, dynamic> _documentOf(File file) {
  final raw = jsonDecode(file.readAsStringSync());
  final nodes = (raw is Map) ? raw['nodes'] : null;
  if (nodes is! Map || nodes.isEmpty) {
    throw StateError('${file.path} 不是 nodes 缓存（缺少 nodes 字段）');
  }
  final document = (nodes.values.first as Map)['document'];
  if (document is! Map) {
    throw StateError('${file.path} 缺少 document');
  }
  return document.cast<String, dynamic>();
}

class _Options {
  _Options({
    required this.positional,
    required this.json,
    required this.root,
    required this.file,
    required this.min,
    required this.out,
  });

  final List<String> positional;
  final bool json;
  final String root;
  final String? file;
  final int min;
  final String? out;
}

_Options _parseOptions(List<String> args) {
  final positional = <String>[];
  var json = false;
  var root = Directory.current.path;
  String? file;
  var min = 1;
  String? out;
  for (final arg in args) {
    if (arg == '--json') {
      json = true;
    } else if (arg.startsWith('--root=')) {
      root = arg.substring('--root='.length);
    } else if (arg.startsWith('--file=')) {
      file = arg.substring('--file='.length);
    } else if (arg.startsWith('--min=')) {
      min = int.tryParse(arg.substring('--min='.length)) ?? 1;
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else if (arg.startsWith('--')) {
      throw StateError('未知选项：$arg');
    } else {
      positional.add(arg);
    }
  }
  return _Options(
    positional: positional,
    json: json,
    root: root,
    file: file,
    min: min,
    out: out,
  );
}
