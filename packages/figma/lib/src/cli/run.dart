import 'dart:async';
import 'dart:io';

import '../cache/budget_guard.dart';
import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import '../common/version.dart';
import 'cli_io.dart';
import 'cache_command.dart';
import 'diff_command.dart';
import 'fetch_command.dart';
import 'frames_command.dart';
import 'get_command.dart';
import 'help.dart';
import 'me_command.dart';
import 'init_command.dart';
import 'spec_command.dart';
import 'tokens_command.dart';
import 'url_command.dart';
import 'usage_command.dart';

/// 取 `--root=<dir>`（默认当前目录）；只用于定位项目缓存。
String _rootOption(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--root=')) return arg.substring('--root='.length);
  }
  return Directory.current.path;
}

const _usage = '''
w_tools_figma — 只读的 Figma 取数与规格导出 CLI（契约见 docs/figma-cli.md）

用法：
  dart run w_tools_figma:figma init   [--force]
  dart run w_tools_figma:figma fetch  file   <fileKey> [--depth=3]
  dart run w_tools_figma:figma fetch  nodes  <fileKey> <id[,id...]> [--depth=<n>]
  dart run w_tools_figma:figma frames [--file=<path>] [--json] [--all] [--name=<s>] [--page=<s>] [--verbose]
  dart run w_tools_figma:figma fetch  images <fileKey> <id[,id...]> [--scale=2]
  dart run w_tools_figma:figma spec   <nodeId> [选项]
  dart run w_tools_figma:figma tokens <nodeId[,nodeId...]> [选项]
  dart run w_tools_figma:figma usage  [--json]
  dart run w_tools_figma:figma cache  stats [--json]
  dart run w_tools_figma:figma cache  clean [--all --yes] [--json]
  dart run w_tools_figma:figma diff   <fileKey> <nodeId> [--json]
  dart run w_tools_figma:figma budget [--set=<n>] [--json]
  dart run w_tools_figma:figma get    <url> <outfile>
  dart run w_tools_figma:figma me     [--json]
  dart run w_tools_figma:figma url    <figma-url | nodeId>
  dart run w_tools_figma:figma help   [command]

选项（spec / tokens 通用）：
  --file=<path>   指定缓存节点树 JSON（默认扫描 nodes-*.json 并选含目标节点的文件）
  --root=<dir>    项目根（默认当前目录），用于定位项目缓存（~/.cache/w_tools/figma/）
  --json          输出 JSON（默认输出 Markdown）
  --node-depth=<n>  spec --json 限制原始 node 的子节点深度（0 = 不带 children）
  --node-only       spec --json 只输出 node，不带 markdown
  --no-markdown     等同 --node-only
  -h, --help      显示帮助

tokens 专属：
  --min=<n>       只列出出现次数 >= n 的项（默认 1）
  --out=<path>    写入文件（默认打印到 stdout）
  --map=<path>    颜色语义映射 YAML（colors: {"#RRGGBB": name}）

fetch 专属：
  --depth=<n>     file 的深度（默认 3）
  --scale=<n>     images 的倍率（默认 2）
  --refresh       绕过缓存重新请求（失败时保留旧缓存）
  --check-stale   用 Tier 3 的 file/meta 判断缓存是否过期（不占 20 次/月，只提示不重拉）
  --no-log        本次不写用量日志（调试用）

diff 专属：
  --if-stale      先用 /meta 比较版本；没变就不拉节点（不再消耗 Tier 1）

退出码：0 成功 / 1 一般错误 / 2 参数错误 / 3 额度受限 / 4 token 问题 / 5 网络错误

说明：
  · spec / tokens 只读本地缓存，不访问 Figma，不消耗额度；
  · token 优先读 FIGMA_TOKEN，其次读 ~/.config/w_tools/figma-token（旧 .figma-token 会自动迁移）；
  · 缓存由 fetch file / nodes / images 生成。
''';

Future<void> runFigmaCli(List<String> args) async {
  if (args.isEmpty) {
    printOut(_usage);
    exitCode = 2;
    return;
  }

  if (args.first == 'help') {
    if (args.length == 1) {
      printOut(_usage);
      exitCode = 0;
    } else {
      printCommandHelp(args[1]);
    }
    return;
  }

  if (args.contains('-h') || args.contains('--help')) {
    if (args.first == '-h' || args.first == '--help') {
      printOut(_usage);
      exitCode = 0;
    } else {
      printCommandHelp(args.first);
    }
    return;
  }

  final command = args.first;
  final rest = args.sublist(1);

  // 老项目的 .figma-cache / .figma-token 一次性搬到用户缓存/配置目录。
  // 迁移失败不应该挡住命令本身。
  try {
    final root = _rootOption(rest);
    final notes = CacheStore(Directory(root)).migrateLegacy();
    for (final note in notes) {
      stderr.writeln(note);
    }
  } on FileSystemException catch (e) {
    stderr.writeln('迁移旧缓存失败（忽略）：${e.message}');
  }

  try {
    switch (command) {
      case 'init':
        runInit(rest);
      case 'frames':
        await runFrames(rest);
      case 'fetch':
        await runFetch(rest);
      case 'usage':
        runUsage(rest);
      case 'cache':
        runCache(rest);
      case 'diff':
        await runDiff(rest);
      case 'budget':
        runBudget(rest);
      case 'get':
        await runGet(rest);
      case 'me':
        await runMe(rest);
      case 'url':
        runUrl(rest);
      case 'spec':
        await runSpec(rest);
      case 'tokens':
        await runTokens(rest);
      case 'version':
        printLine('w_tools_figma $figmaVersion');
      default:
        stderr.writeln('未知命令：$command\n');
        printOut(_usage);
        exitCode = 2;
    }
  } on BudgetExceededException catch (e) {
    stderr.writeln(e.reason);
    exitCode = 3;
  } on FigmaTokenException catch (e) {
    stderr.writeln(e.message);
    exitCode = 4;
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 2;
  } on FigmaHttpException catch (e) {
    stderr.writeln(e);
    exitCode = e.isRateLimited ? 3 : (e.statusCode == 401 || e.statusCode == 403 ? 4 : 1);
  } on TimeoutException {
    stderr.writeln('网络超时；检查网络或稍后重试');
    exitCode = 5;
  } on HttpException catch (e) {
    stderr.writeln('网络错误：${e.message}');
    exitCode = 5;
  } on SocketException catch (e) {
    stderr.writeln('网络错误：${e.message}');
    exitCode = 5;
  } on FileSystemException catch (e) {
    stderr.writeln('读取失败：${e.message}（${e.path}）');
    exitCode = 1;
  }
}
