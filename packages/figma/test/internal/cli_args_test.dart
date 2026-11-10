import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/args.dart';

void main() {
  test('rootOption：显式 --root 优先，缺省用当前目录', () {
    expect(rootOption(<String>['spec', '1:2', '--root=/tmp/x']), '/tmp/x');
    expect(rootOption(const <String>[]), Directory.current.path);
    expect(parseOptions(<String>['--root=/tmp/y']).root, '/tmp/y');
    expect(parseOptions(const <String>[]).root, Directory.current.path);
  });

  test('默认值 + 全量 flag 组合（解析器对拍）', () {
    final defaults = parseOptions(const <String>[]);
    expect(defaults.json, isFalse);
    expect(defaults.root, Directory.current.path);
    expect(defaults.file, isNull);
    expect(defaults.min, 1);
    expect(defaults.out, isNull);
    expect(defaults.depth, isNull);
    expect(defaults.scale, 2);
    expect(defaults.nodeDepth, isNull);
    expect(defaults.refresh, isFalse);
    expect(defaults.log, isTrue);
    expect(defaults.budgetSet, isNull);
    expect(defaults.checkStale, isFalse);
    expect(defaults.force, isFalse);
    expect(defaults.ifStale, isFalse);
    expect(defaults.ignoreBudget, isFalse);
    expect(defaults.nodeOnly, isFalse);
    expect(defaults.mapFile, isNull);
    expect(defaults.all, isFalse);
    expect(defaults.yes, isFalse);
    expect(defaults.nameFilter, isNull);
    expect(defaults.pageFilter, isNull);
    expect(defaults.verbose, isFalse);
    expect(defaults.seen, isEmpty);

    final all = parseOptions(const <String>[
      '--json',
      '--root=/r',
      '--file=f',
      '--min=2',
      '--out=o',
      '--depth=2',
      '--scale=3',
      '--node-depth=0',
      '--refresh',
      '--no-log',
      '--force',
      '--set=5',
      '--check-stale',
      '--if-stale',
      '--ignore-budget',
      '--no-markdown',
      '--all',
      '-y',
      '--name=n',
      '--page=p',
      '--verbose',
      '--map=m',
    ]);
    expect(all.json, isTrue);
    expect(all.root, '/r');
    expect(all.file, 'f');
    expect(all.min, 2);
    expect(all.out, 'o');
    expect(all.depth, 2);
    expect(all.scale, 3);
    expect(all.nodeDepth, 0);
    expect(all.refresh, isTrue);
    expect(all.log, isFalse);
    expect(all.force, isTrue);
    expect(all.budgetSet, 5);
    expect(all.checkStale, isTrue);
    expect(all.ifStale, isTrue);
    expect(all.ignoreBudget, isTrue);
    expect(all.nodeOnly, isTrue);
    expect(all.all, isTrue);
    expect(all.yes, isTrue);
    expect(all.nameFilter, 'n');
    expect(all.pageFilter, 'p');
    expect(all.verbose, isTrue);
    expect(all.mapFile, 'm');
    expect(all.seenText['node-only'], '--no-markdown');
  });

  test('布尔 flag 不接受 =值（与旧解析器一致）', () {
    expect(
      () => parseOptions(const <String>['--json=true']),
      throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--json=true'))),
    );
  });

  test('未知选项保留中文报错', () {
    expect(
      () => parseOptions(const <String>['--wat']),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('未知选项'))),
    );
  });

  test('取值选项支持 `--x v` 空格形态', () {
    expect(parseOptions(<String>['--depth', '3']).depth, 3);
    expect(parseOptions(<String>['--root', '/tmp/x']).root, '/tmp/x');
    expect(parseOptions(<String>['--node-depth', '0']).nodeDepth, 0);
    expect(parseOptions(<String>['--set', '20']).budgetSet, 20);
    expect(() => parseOptions(<String>['--depth']), throwsFormatException);
    expect(() => parseOptions(<String>['--name']), throwsFormatException);
  });

  test('--no-markdown 被拒时报用户写的名字，不报 --node-only', () {
    final options = parseOptions(<String>['--no-markdown']);

    expect(options.nodeOnly, isTrue);
    expect(options.seen, contains('node-only'), reason: 'allow-list 仍按规范名判断');

    expect(
      () => rejectUnsupported(options, <String>{'json'}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('--no-markdown'), isNot(contains('--node-only'))),
        ),
      ),
    );
  });

  test('别名 -y 被拒时也照原样显示', () {
    final options = parseOptions(<String>['-y']);

    expect(
      () => rejectUnsupported(options, <String>{'json'}),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('-y'))),
    );
  });
}
