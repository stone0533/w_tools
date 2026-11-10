import 'dart:async';
import 'dart:io';

import '../cache/budget_guard.dart';
import '../cache/cache_store.dart';
import '../client/figma_client.dart';
import 'args.dart';
import 'cache_handler.dart';
import 'budget_handler.dart';
import 'cli_io.dart';
import 'diff_handler.dart';
import 'fetch_handler.dart';
import 'frames_handler.dart';
import 'get_handler.dart';
import 'help.dart';
import 'init_handler.dart';
import 'me_handler.dart';
import 'migration.dart';
import 'spec_handler.dart';
import 'tokens_handler.dart';
import 'url_handler.dart';
import 'usage_handler.dart';
import 'version.dart';

Future<void> runFigmaCli(List<String> args) async {
  if (args.isEmpty) {
    printOut(usageText);
    exitCode = 2;
    return;
  }

  if (args.first == 'help') {
    if (args.length == 1) {
      printOut(usageText);
      exitCode = 0;
    } else {
      printCommandHelp(args[1]);
    }
    return;
  }

  if (args.contains('-h') || args.contains('--help')) {
    if (args.first == '-h' || args.first == '--help') {
      printOut(usageText);
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
    final root = rootOption(rest);
    final notes = ensureLegacyMigrated(CacheStore(Directory(root)));
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
        printOut(usageText);
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
