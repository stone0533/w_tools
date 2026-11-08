import 'dart:io';

import 'package:test/test.dart';

/// 仓库级文档回归：这些文件不随包发布，但会直接影响用户 / AI 的写法。
void main() {
  test('ASYNC-003：分页 footer 的监听说明包含 hasMoreListenable', () {
    final recipe = File('../../docs/recipes/paged-list.md').readAsStringSync();
    final example = File('../../packages/async/example/README.md').readAsStringSync();

    expect(recipe, contains('hasMoreListenable'));
    expect(example, contains('hasMoreListenable'));
  });

  test('ASYNC-005：async 源码注释不再引用已删除 API / 旧 null 语义', () {
    final text = Directory('../../packages/async/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(text, isNot(contains('tryRunValue')));
    expect(text, isNot(contains('后续任务会在开始前直接返回 null')));
    expect(text, isNot(contains('并返回 null')));
  });

  test('ASYNC-006：modules 文档的「当前」版本跟随 pubspec', () {
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(File('../../packages/async/pubspec.yaml').readAsStringSync())!.group(1)!;
    final module = File('../../docs/modules/async_module.md').readAsStringSync();

    expect(module, contains('当前 $version'));
  });

  test('ASYNC-017：naming.md 登记 async 的 Activity / Views 角色', () {
    final naming = File('../../docs/naming.md').readAsStringSync();

    expect(naming, contains('`Activity`'));
    expect(naming, contains('`Views`'));
  });

  test('ASYNC-020：async CHANGELOG 标题在第一行', () {
    final log = File('../../packages/async/CHANGELOG.md').readAsStringSync();

    expect(log.split('\n').first, '# Changelog');
  });

  test('ASYNC-023：README 写明并发组合器的落败者行为', () {
    final readme = File('../../packages/async/README.md').readAsStringSync();

    expect(readme, contains('其余 Future 会继续执行'));
    expect(readme, contains('不会取消落败者'));
    expect(readme, contains('只上报第一个错误'));
  });

  test('ASYNC-009：分页追加的规模边界已写明', () {
    final readme = File('../../packages/async/README.md').readAsStringSync();

    expect(readme, contains('O(n)'));
    expect(readme, contains('万级'));
  });

  test('ASYNC-024：WAsyncState.errorMessage 的用途已写明', () {
    final module = File('../../docs/modules/async_module.md').readAsStringSync();

    expect(module, contains('errorMessage'));
  });
}
