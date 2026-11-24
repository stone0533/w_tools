import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:w_tools_device/src/input.dart';
import 'package:w_tools_device/src/shell.dart';

/// 记录外部命令调用；按参数前缀模拟 cliclick 失败，按配置模拟 swift 输出。
class _TimeoutShell extends Shell {
  Duration? seen;

  @override
  Future<ProcessResult> run(String exe, List<String> args) async =>
      throw UnimplementedError('runWithTimeout should be used');

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async => Uint8List(0);

  @override
  Future<ProcessResult> runWithTimeout(
    String exe,
    List<String> args,
    Duration timeout,
  ) async {
    seen = timeout;
    return ProcessResult(0, 0, 'true', '');
  }
}

class _FakeShell extends Shell {
  _FakeShell({
    this.failPrefixes = const {},
    this.swiftOutput = 'false',
    this.swiftExit = 0,
  });

  final Set<String> failPrefixes;
  final String swiftOutput;
  final int swiftExit;
  final calls = <List<String>>[];

  @override
  Future<ProcessResult> run(String exe, List<String> args) async {
    calls.add([exe, ...args]);
    if (exe == 'swift') {
      return ProcessResult(0, swiftExit, swiftExit == 0 ? swiftOutput : '', 'boom');
    }
    final fail = args.any((arg) => failPrefixes.any(arg.startsWith));
    return ProcessResult(0, fail ? 1 : 0, '', fail ? 'boom' : '');
  }

  @override
  Future<Uint8List> runBytes(String exe, List<String> args) async => Uint8List(0);
}

List<List<String>> _cliclickCalls(_FakeShell shell) =>
    shell.calls.where((call) => call.first == 'cliclick').toList();

void main() {
  test('tap 默认先 du:. 释放，再点目标（同一次 cliclick 调用）', () async {
    final shell = _FakeShell();
    await Input(shell: shell).tap(12.4, 30.6);
    expect(_cliclickCalls(shell), [
      ['cliclick', 'du:.', 'c:12,31'],
    ]);
  });

  test('--no-release-mouse 对应的 releaseFirst=false 只发 c:', () async {
    final shell = _FakeShell();
    await Input(shell: shell).tap(12.4, 30.6, releaseFirst: false);
    expect(_cliclickCalls(shell), [
      ['cliclick', 'c:12,31'],
    ]);
  });

  test('drag 默认先释放，正常路径只调用一次，且以 du: 结尾', () async {
    final shell = _FakeShell();
    await Input(shell: shell).drag(0, 0, 30, 40);
    final calls = _cliclickCalls(shell);
    expect(calls, hasLength(1));
    expect(calls.single[1], 'du:.');
    expect(calls.single.last, 'du:30,40');
  });

  test('drag 失败（非零退出 / 超时）时补发幂等释放，并保留原始异常', () async {
    final shell = _FakeShell(failPrefixes: {'dd:'});
    await expectLater(
      Input(shell: shell).drag(0, 0, 30, 40),
      throwsA(
        isA<ProcessException>().having((e) => e.message, 'message', contains('boom')),
      ),
    );
    final calls = _cliclickCalls(shell);
    expect(calls, hasLength(2));
    expect(calls.last, ['cliclick', 'du:.']);
  });

  test('释放本身失败也不覆盖原始异常', () async {
    final shell = _FakeShell(failPrefixes: {'dd:', 'du:'});
    await expectLater(
      Input(shell: shell).drag(0, 0, 30, 40),
      throwsA(isA<ProcessException>()),
    );
    expect(_cliclickCalls(shell).last, ['cliclick', 'du:.']);
  });

  test('mouseButtonDown 解析 swift 输出：true / false / 失败返回 null', () async {
    expect(await Input(shell: _FakeShell(swiftOutput: 'true')).mouseButtonDown(), isTrue);
    expect(await Input(shell: _FakeShell(swiftOutput: 'false')).mouseButtonDown(), isFalse);
    expect(await Input(shell: _FakeShell(swiftExit: 1)).mouseButtonDown(), isNull);
    expect(await Input(shell: _FakeShell(swiftOutput: 'nope')).mouseButtonDown(), isNull);
  });

  test('release 用 du:. 并返回是否成功', () async {
    expect(await Input(shell: _FakeShell()).release(), isTrue);
    expect(await Input(shell: _FakeShell(failPrefixes: {'du:'})).release(), isFalse);
  });

  test('探针 / 释放使用短超时（不拖住 verify）', () async {
    final probe = _TimeoutShell();
    expect(await Input(shell: probe).mouseButtonDown(), isTrue);
    expect(probe.seen, isNotNull);
    expect(probe.seen!.inSeconds, lessThanOrEqualTo(10));

    final release = _TimeoutShell();
    expect(await Input(shell: release).release(), isTrue);
    expect(release.seen, isNotNull);
    expect(release.seen!.inSeconds, lessThanOrEqualTo(10));
  });
}
