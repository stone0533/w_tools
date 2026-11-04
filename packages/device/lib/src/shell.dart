import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// 极薄的进程封装：便于测试时替换（不直接依赖 `Process.run`）。
abstract class Shell {
  Future<ProcessResult> run(String exe, List<String> args);
  Future<ProcessResult> runOrThrow(String exe, List<String> args);

  /// 取**原始字节**（截图等二进制输出；默认实现按 UTF-8 转一遍，仅供 fake 用）。
  Future<Uint8List> runBytes(String exe, List<String> args);
}

class ProcessShell implements Shell {
  /// [timeout] 是每条外部命令的上限：`xcrun` / `adb` 卡死时不能把整个 CI 拖住。
  /// 默认 120 秒（模拟器冷启动 + `bootstatus` 可能比较久）。
  const ProcessShell({this.timeout = const Duration(seconds: 120)});

  final Duration timeout;

  Future<(int, List<int>, List<int>)> _run(String exe, List<String> args) async {
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
    final (code, out, err) = await _run(exe, args);
    return ProcessResult(
      0,
      code,
      utf8.decode(out, allowMalformed: true),
      utf8.decode(err, allowMalformed: true),
    );
  }

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async {
    final (code, out, err) = await _run(exe, args);
    if (code != 0) {
      throw ProcessException(exe, args, utf8.decode(err, allowMalformed: true).trim(), code);
    }
    return Uint8List.fromList(out);
  }

  @override
  Future<ProcessResult> runOrThrow(String exe, List<String> args) async {
    final r = await run(exe, args);
    if (r.exitCode != 0) {
      throw ProcessException(exe, args, '${r.stderr}'.trim(), r.exitCode);
    }
    return r;
  }
}
