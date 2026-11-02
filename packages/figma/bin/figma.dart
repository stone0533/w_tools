import 'dart:convert';
import 'dart:io';

import 'package:w_tools_figma/w_tools_figma.dart';

const _usage = '''
w_tools_figma — 只读的 Figma 取数与规格导出 CLI（契约见 docs/figma-cli.md）

用法：
  dart run w_tools_figma:figma init   [--force]
  dart run w_tools_figma:figma fetch  file   <fileKey> [--depth=3]
  dart run w_tools_figma:figma fetch  nodes  <fileKey> <id[,id...]>
  dart run w_tools_figma:figma fetch  images <fileKey> <id[,id...]> [--scale=2]
  dart run w_tools_figma:figma spec   <nodeId> [选项]
  dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [选项]
  dart run w_tools_figma:figma usage  [--json]
  dart run w_tools_figma:figma url    <figma-url | nodeId>

选项（spec / tokens 通用）：
  --file=<path>   指定缓存节点树 JSON（默认取 .figma-cache/nodes-*.json 中最大的一个）
  --root=<dir>    项目根（默认当前目录），用于定位 .figma-cache/
  --json          输出 JSON（默认输出 Markdown）
  -h, --help      显示帮助

tokens 专属：
  --min=<n>       只列出出现次数 >= n 的项（默认 1）
  --out=<path>    写入文件（默认打印到 stdout）

fetch 专属：
  --depth=<n>     file 的深度（默认 3）
  --scale=<n>     images 的倍率（默认 2）
  --refresh       删除缓存并强制重拉（唯一会绕过缓存的开关）

退出码：0 成功 / 1 一般错误 / 2 参数错误 / 3 额度受限 / 4 token 问题 / 5 网络错误

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
      case 'init':
        _runInit(rest);
      case 'fetch':
        await _runFetch(rest);
      case 'usage':
        _runUsage(rest);
      case 'url':
        _runUrl(rest);
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
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 2;
  } on FigmaHttpException catch (e) {
    stderr.writeln(e);
    exitCode = e.isRateLimited ? 3 : (e.statusCode == 401 || e.statusCode == 403 ? 4 : 1);
  } on SocketException catch (e) {
    stderr.writeln('网络错误：${e.message}');
    exitCode = 5;
  } on FileSystemException catch (e) {
    stderr.writeln('读取失败：${e.message}（${e.path}）');
    exitCode = 1;
  }
}

void _runInit(List<String> args) {
  final force = args.contains('--force');
  final options = _parseOptions(args);
  final store = CacheStore(Directory(options.root));
  final result = InitCommand(store).run(force: force);
  stderr.writeln(result.tokenCreated ? '已创建 .figma-token（记得填入 figd_ 令牌）' : '.figma-token 已存在');
  if (result.gitignoreAdded.isNotEmpty) {
    stderr.writeln('.gitignore 已追加：${result.gitignoreAdded.join(', ')}');
  }
  stderr.writeln('缓存目录：${result.cacheDir.path}');
}

Future<void> _runFetch(List<String> args) async {
  final options = _parseOptions(args);
  final positional = options.positional;
  if (positional.length < 2) {
    stderr.writeln('fetch 用法：fetch <file|nodes|images> <fileKey> [ids]');
    exitCode = 2;
    return;
  }
  final kind = positional[0];
  final fileKey = positional[1];
  final idsRaw = positional.length > 2 ? positional[2] : null;
  final ids =
      idsRaw == null ? const <String>[] : idsRaw.split(',').where((e) => e.isNotEmpty).toList();
  if ((kind == 'nodes' || kind == 'images') && ids.isEmpty) {
    stderr.writeln('$kind 需要 ids，例如：fetch $kind <fileKey> 1862:9222');
    exitCode = 2;
    return;
  }

  final store = CacheStore(Directory(options.root));
  final token = _readToken(store);
  final client = HttpFigmaClient(token: token);
  final command = FetchCommand(store: store, client: client, log: options.log);
  try {
    final result = switch (kind) {
      'file' =>
        await command.file(fileKey: fileKey, depth: options.depth, refresh: options.refresh),
      'nodes' => await command.nodes(fileKey: fileKey, ids: ids, refresh: options.refresh),
      'images' => await command.images(
          fileKey: fileKey, ids: ids, scale: options.scale, refresh: options.refresh),
      _ => throw FormatException('未知的 fetch 类型：$kind（file / nodes / images）'),
    };
    if (result.fromCache) {
      stderr.writeln('# cache hit: ${result.file.path}');
    } else {
      stderr.writeln('# fetched: ${result.file.path}');
    }
    if (options.json) {
      stdout.writeln(jsonEncode({
        'schema': 'w_tools_figma.fetch/1',
        'cacheFile': result.file.path,
        'fromCache': result.fromCache,
        'tierCalls': result.tierCalls,
      }));
    }
  } finally {
    client.close();
  }
}

void _runUsage(List<String> args) {
  final options = _parseOptions(args);
  final store = CacheStore(Directory(options.root));
  final summary = UsageCommand(store).run();
  if (options.json) {
    stdout.writeln(jsonEncode({
      'schema': 'w_tools_figma.usage/1',
      'month': summary.month,
      'used': summary.used,
      'limit': summary.limit,
      'remaining': summary.remaining,
      'recent': [
        for (final e in summary.recent) {'at': e.at, 'kind': e.kind, 'cache': e.cacheFile},
      ],
    }));
    return;
  }
  stdout.writeln('Tier 1 calls this month (${summary.month}): ${summary.used} / ${summary.limit}');
  if (summary.isNearLimit) {
    stdout.writeln('⚠️ 已用 ${summary.used}/${summary.limit}，本月剩余 ${summary.remaining} 次');
  }
  if (summary.recent.isEmpty) {
    stdout.writeln('（本月还没有调用记录）');
  } else {
    stdout.writeln('最近 ${summary.recent.length} 条：');
    for (final e in summary.recent) {
      stdout.writeln('  ${e.at}  ${e.kind}  ${e.cacheFile}');
    }
  }
}

void _runUrl(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('url 需要 Figma 链接或 nodeId');
    exitCode = 2;
    return;
  }
  final target = const UrlCommand().run(args.first);
  stdout.writeln('fileKey=${target.fileKey}  nodeId=${target.nodeId ?? ''}');
}

String _readToken(CacheStore store) {
  final file = store.tokenFile;
  if (!file.existsSync()) {
    throw StateError('缺少 ${file.path}，先跑 init 并填入 figd_ 令牌');
  }
  final token = file.readAsStringSync().trim();
  if (token.isEmpty || token.contains('REPLACE_ME')) {
    throw StateError('${file.path} 里还是模板内容，请填入真实的 figd_ 令牌');
  }
  return token;
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
    required this.depth,
    required this.scale,
    required this.refresh,
    required this.log,
  });

  final List<String> positional;
  final bool json;
  final String root;
  final String? file;
  final int min;
  final String? out;
  final int depth;
  final int scale;
  final bool refresh;
  final bool log;
}

_Options _parseOptions(List<String> args) {
  final positional = <String>[];
  var json = false;
  var root = Directory.current.path;
  String? file;
  var min = 1;
  String? out;
  var depth = 3;
  var scale = 2;
  var refresh = false;
  var log = true;
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
    } else if (arg.startsWith('--depth=')) {
      depth = int.tryParse(arg.substring('--depth='.length)) ?? 3;
    } else if (arg.startsWith('--scale=')) {
      scale = int.tryParse(arg.substring('--scale='.length)) ?? 2;
    } else if (arg == '--refresh') {
      refresh = true;
    } else if (arg == '--no-log') {
      log = false;
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
    depth: depth,
    scale: scale,
    refresh: refresh,
    log: log,
  );
}
