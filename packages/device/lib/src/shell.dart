import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 极薄的进程封装：便于测试时替换（不直接依赖 `Process.run`）。
///
/// 只暴露两个原语：文本输出 [run] 与原始字节 [runBytes]；
/// [runOrThrow] 由基类派生，fake 不需要重复实现。
abstract class Shell {
  const Shell();

  Future<ProcessResult> run(String exe, List<String> args);

  /// 取**原始字节**（截图等二进制输出）。
  Future<Uint8List> runBytes(String exe, List<String> args);

  /// 带自定义超时执行；默认实现忽略 [timeout]（fake 用），[ProcessShell] 会真正生效。
  Future<ProcessResult> runWithTimeout(
    String exe,
    List<String> args,
    Duration timeout,
  ) =>
      run(exe, args);

  Future<ProcessResult> runOrThrow(String exe, List<String> args) async {
    final result = await run(exe, args);
    if (result.exitCode != 0) {
      throw ProcessException(exe, args, '${result.stderr}'.trim(), result.exitCode);
    }
    return result;
  }
}

class ProcessShell extends Shell {
  /// [timeout] 是每条外部命令的上限：`xcrun` / `adb` 卡死时不能把整个 CI 拖住。
  /// 默认 120 秒（模拟器冷启动 + `bootstatus` 可能比较久）。
  const ProcessShell({this.timeout = const Duration(seconds: 120)});

  final Duration timeout;

  Future<(int, List<int>, List<int>)> _run(
    String exe,
    List<String> args,
    Duration timeout,
  ) async {
    final process = await Process.start(exe, args, runInShell: false);
    final outFuture = process.stdout.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    final errFuture = process.stderr.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    try {
      final code = await process.exitCode.timeout(timeout);
      return (code, await outFuture, await errFuture);
    } on TimeoutException {
      process.kill();
      throw ProcessException(exe, args, '命令超时（${timeout.inSeconds}s）', -1);
    }
  }

  @override
  Future<ProcessResult> run(String exe, List<String> args) async {
    final (code, out, err) = await _run(exe, args, timeout);
    return _result(code, out, err);
  }

  @override
  Future<ProcessResult> runWithTimeout(
    String exe,
    List<String> args,
    Duration timeout,
  ) async {
    final (code, out, err) = await _run(exe, args, timeout);
    return _result(code, out, err);
  }

  ProcessResult _result(int code, List<int> out, List<int> err) => ProcessResult(
        0,
        code,
        utf8.decode(out, allowMalformed: true),
        utf8.decode(err, allowMalformed: true),
      );

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async {
    final (code, out, err) = await _run(exe, args, timeout);
    if (code != 0) {
      throw ProcessException(exe, args, utf8.decode(err, allowMalformed: true).trim(), code);
    }
    return Uint8List.fromList(out);
  }
}
