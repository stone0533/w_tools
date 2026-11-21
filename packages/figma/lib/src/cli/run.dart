import 'dart:async';
import 'dart:io';

import '../client/figma_client.dart';
import 'cache_handler.dart';
import 'cli_io.dart';
import 'diff_handler.dart';
import 'fetch_handler.dart';
import 'frames_handler.dart';
import 'get_handler.dart';
import 'help.dart';
import 'init_handler.dart';
import 'me_handler.dart';
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

  // 常见别名：`--version` / `-v` 与 `version` 等价，避免被当成未知命令。
  if (args.length == 1 && (args.first == '--version' || args.first == '-v')) {
    printLine('w_tools_figma $figmaVersion');
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

  if (command.startsWith('-')) {
    stderr.writeln('选项要放在命令之后，例如：figma frames --root=<dir>');
    exitCode = 2;
    return;
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
  } on TypeError catch (e) {
    // 缓存被手改 / 旧结构 / 字段缺失时，不要把 Dart 栈直接抛给用户。
    stderr.writeln('缓存结构异常：$e；用 --refresh 重新拉取，或 cache clean 后重试');
    exitCode = 1;
  } on Error catch (e) {
    // RangeError / ArgumentError 等：坏缓存不应以 exit 255 和 Dart 栈结束。
    stderr.writeln(
      '缓存结构异常（${e.runtimeType}）：$e；用 --refresh 重新拉取，或 cache clean 后重试',
    );
    exitCode = 1;
  }
}
