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
  const ProcessShell();

  @override
  Future<ProcessResult> run(String exe, List<String> args) =>
      Process.run(exe, args, runInShell: false);

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async {
    final r = await Process.run(exe, args, runInShell: false, stdoutEncoding: null);
    if (r.exitCode != 0) {
      throw ProcessException(exe, args, '${r.stderr}'.trim(), r.exitCode);
    }
    return r.stdout as Uint8List;
  }

  @override
  Future<ProcessResult> runOrThrow(String exe, List<String> args) async {
    final r = await run(exe, args);
    if (r.exitCode != 0) {
      throw ProcessException(
        exe,
        args,
        '${r.stderr}'.trim(),
        r.exitCode,
      );
    }
    return r;
  }
}
