import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('DOC-003 feedback --help 说明 --gh 不可用时退出 3 且只查本地', () {
    final result = Process.runSync(
      Platform.resolvedExecutable,
      <String>['run', 'bin/feedback.dart', '--help'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final output = '${result.stdout}';
    expect(output, contains('gh 不可用时退出 3'));
    expect(output, contains('去掉 --gh'));
  });

  test('DOC-004 docs/agents/cli.md 写明 --gh 退出 3 且只查本地', () {
    final text = File(p.join('..', '..', 'docs', 'agents', 'cli.md')).readAsStringSync();
    expect(text, contains('feedback search --gh'));
    expect(text, contains('退出 `3`'));
    expect(text, contains('去掉 `--gh`'));
  });

  test('DOC-005 doctor --write-config help/docs 与“已存在报错”行为一致', () {
    final result = Process.runSync(
      Platform.resolvedExecutable,
      <String>['run', 'bin/doctor.dart', '--help'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('已存在报错'));

    final text = File(p.join('..', '..', 'docs', 'conventions.md')).readAsStringSync();
    expect(text, contains('已存在报错'));
    expect(text, isNot(contains('已存在则跳过')));
  });

  test('DOC-006 doctor --write-config 说明 .bak 轮转', () {
    final result = Process.runSync(
      Platform.resolvedExecutable,
      <String>['run', 'bin/doctor.dart', '--help'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('.bak.<timestamp>'));

    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('.bak.<timestamp>'));

    final conventions = File(
      p.join('..', '..', 'docs', 'conventions.md'),
    ).readAsStringSync();
    expect(conventions, contains('.bak.<timestamp>'));
  });
}
