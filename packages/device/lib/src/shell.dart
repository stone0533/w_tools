import 'dart:io';

/// 极薄的进程封装：便于测试时替换（不直接依赖 `Process.run`）。
abstract class Shell {
  Future<ProcessResult> run(String exe, List<String> args);
  Future<ProcessResult> runOrThrow(String exe, List<String> args);
}

class ProcessShell implements Shell {
  const ProcessShell();

  @override
  Future<ProcessResult> run(String exe, List<String> args) =>
      Process.run(exe, args, runInShell: false);

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
