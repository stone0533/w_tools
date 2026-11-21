import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/args.dart';

void main() {
  test('--root 默认当前目录，显式值优先', () {
    final dir = Directory.systemTemp.createTempSync('figma_args_');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(parseCommand(const <String>[], 'spec').root, Directory.current.path);
    expect(parseCommand(<String>['--root=${dir.path}'], 'spec').root, dir.path);
    expect(parseCommand(<String>['--root', dir.path], 'spec').root, dir.path);
  });

  test('--root 为空或目录不存在时报参数错误', () {
    expect(() => parseCommand(<String>['--root='], 'spec').root, throwsFormatException);
    expect(
      () => parseCommand(<String>['--root=/no/such/dir/for/figma'], 'spec').root,
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('不存在'))),
    );
  });

  test('每个命令只接受自己的选项', () {
    expect(parseCommand(<String>['--json'], 'spec').json, isTrue);
    expect(parseCommand(<String>['--depth=2'], 'fetch').depth, 2);
    expect(parseCommand(<String>['--depth', '2'], 'fetch').depth, 2);
    expect(parseCommand(<String>['--min=3'], 'tokens').min, 3);
    expect(parseCommand(<String>['--set=5'], 'usage').budgetSet, 5);
    expect(parseCommand(<String>['--all', '-y'], 'cache').all, isTrue);
    expect(parseCommand(<String>['--all', '-y'], 'cache').yes, isTrue);
    expect(parseCommand(<String>['--files'], 'cache').files, isTrue);
    expect(parseCommand(<String>['--legacy'], 'cache').legacy, isTrue);
    expect(parseCommand(<String>['--file=nodes.json'], 'cache').file, 'nodes.json');
    expect(parseCommand(<String>['--skip-markdown'], 'tokens').skipMarkdown, isTrue);
    expect(parseCommand(<String>['--skip-name-prefix=A,B'], 'spec').skipNamePrefix, 'A,B');
    expect(parseCommand(<String>['--skip-name-prefix=A,B'], 'tokens').skipNamePrefix, 'A,B');
    expect(parseCommand(<String>['--allow-depth'], 'spec').allowDepth, isTrue);
    expect(parseCommand(<String>['--allow-depth'], 'tokens').allowDepth, isTrue);
    expect(parseCommand(<String>['--node-depth=0'], 'spec').nodeDepth, 0);
    expect(parseCommand(<String>['--force'], 'init').force, isTrue);
    expect(parseCommand(<String>['--if-stale'], 'diff').ifStale, isTrue);
    expect(parseCommand(<String>['--scale=3'], 'fetch').scale, 3);
    expect(parseCommand(<String>['--with-id'], 'spec').withId, isTrue);
    expect(parseCommand(<String>['--with-layout'], 'spec').withLayout, isTrue);
    expect(parseCommand(<String>['--depth=0', '--limit=2'], 'frames').depth, 0);
    expect(parseCommand(<String>['--depth=0', '--limit=2'], 'frames').limit, 2);
  });

  test('跨命令选项按未知选项拒绝', () {
    expect(
      () => parseCommand(<String>['--min=3'], 'spec'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--min'))),
    );
    expect(
      () => parseCommand(<String>['--root=/x'], 'url'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--root'))),
    );
    expect(
      () => parseCommand(<String>['--json'], 'get'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--json'))),
    );
  });

  test('布尔 flag 不接受 =值', () {
    expect(
      () => parseCommand(<String>['--json=true'], 'spec'),
      throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--json=true'))),
    );
  });

  test('未知选项保留中文报错', () {
    expect(
      () => parseCommand(<String>['--wat'], 'spec'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('未知选项'))),
    );
  });

  test('取值选项支持 `--x v` 空格形态，缺值报中文', () {
    final dir = Directory.systemTemp.createTempSync('figma_args_');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(parseCommand(<String>['--root', dir.path], 'spec').root, dir.path);
    expect(parseCommand(<String>['--node-depth', '0'], 'spec').nodeDepth, 0);
    expect(parseCommand(<String>['--set', '20'], 'usage').budgetSet, 20);
    expect(() => parseCommand(<String>['--depth'], 'fetch'), throwsFormatException);
    expect(() => parseCommand(<String>['--name'], 'frames'), throwsFormatException);
  });

  test('--no-markdown 在 0.13.0 已删除', () {
    expect(
      () => parseCommand(<String>['--no-markdown'], 'spec'),
      throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', contains('未知选项：--no-markdown'))),
    );
  });

  test('--no-log 在 0.14.0 已删除', () {
    expect(
      () => parseCommand(<String>['--no-log'], 'fetch'),
      throwsA(
          isA<FormatException>().having((e) => e.message, 'message', contains('未知选项：--no-log'))),
    );
  });

  test('--ignore-budget 在 1.0.0 已删除', () {
    expect(
      () => parseCommand(<String>['--ignore-budget'], 'fetch'),
      throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', contains('未知选项：--ignore-budget'))),
    );
  });

  test('别名 -y 只在 cache 里有效', () {
    expect(parseCommand(<String>['-y'], 'cache').yes, isTrue);
    expect(
      () => parseCommand(<String>['-y'], 'spec'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('-y'))),
    );
  });

  test('位置参数上限', () {
    final args = parseCommand(<String>['a', 'b'], 'url');
    expect(args.positional, <String>['a', 'b']);
    expect(() => rejectExtra(args, 1), throwsFormatException);
    expect(() => rejectExtra(args, 2), returnsNormally);
  });
}
