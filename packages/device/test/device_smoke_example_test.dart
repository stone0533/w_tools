import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// 用 PATH 上的假 `dart` 跑真实示例，验证重试成功后 JSON 里不残留失败步骤。
void main() {
  late Directory root;
  late Directory bin;

  setUp(() {
    root = Directory.systemTemp.createTempSync('device_smoke_fake_');
    bin = Directory('${root.path}/bin')..createSync();
    final fakeDart = File('${bin.path}/dart')..writeAsStringSync(r'''#!/bin/sh
echo "$@" >> "$FAKE_DIR/calls.log"
case "$*" in
  *"device list --json"*)
    echo '{"ok":true,"devices":[{"name":"Fake","booted":true}]}'
    ;;
  *"device calibrate --json"*)
    echo '{"ok":true,"device":{"width":400,"height":800}}'
    ;;
  *"device verify"*)
    n=$(cat "$FAKE_DIR/verify_count" 2>/dev/null || echo 0)
    n=$((n+1))
    echo "$n" > "$FAKE_DIR/verify_count"
    if [ "$n" -eq 1 ]; then
      echo '{"ok":false,"changed":false,"error":"not changed"}'
      exit 1
    fi
    if [ "$n" -eq 4 ]; then
      echo '{"ok":false,"changed":false}'
      exit 1
    fi
    echo '{"ok":true,"changed":true}'
    exit 0
    ;;
esac
exit 0
''');
    Process.runSync('chmod', ['+x', fakeDart.path]);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('重试成功后 steps 不再残留 ok:false', () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'example/tool/device_smoke.dart', '--json', '--tabs=2'],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'PATH': '${bin.path}:${Platform.environment['PATH'] ?? ''}',
        'FAKE_DIR': root.path,
      },
    );

    expect(
      result.exitCode,
      0,
      reason: 'stdout=${result.stdout}\nstderr=${result.stderr}',
    );
    final json = jsonDecode('${result.stdout}'.trim()) as Map<String, dynamic>;
    expect(json['ok'], isTrue);
    final steps = (json['steps'] as List).cast<Map<String, dynamic>>();
    expect(
      steps.where((step) => step['ok'] != true),
      isEmpty,
      reason: '通过时不应残留失败步骤：$steps',
    );
    expect(
      steps.where((step) => step['step'] == 'tab 0').length,
      1,
      reason: '同一个步骤只应出现一次：$steps',
    );
  }, skip: Platform.isWindows ? '假 dart 用 sh 脚本，仅 POSIX' : false);
}
