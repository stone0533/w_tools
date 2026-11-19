import 'dart:io';

import 'package:test/test.dart';

/// 仓库级文档回归：这些文件不随包发布，但会直接影响用户 / AI 的写法。
void main() {
  test('ASYNC-003：分页 footer 统一读 snapshot', () {
    final recipe = File('../../docs/recipes/paged-list.md').readAsStringSync();
    final example = File('../../packages/async/example/README.md').readAsStringSync();

    expect(recipe, contains('snapshot.footerStatus'));
    expect(example, contains('snapshot.footerStatus'));
    expect(recipe, isNot(contains('hasMoreListenable')));
    expect(example, isNot(contains('hasMoreListenable')));
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

  test('ASYNC-025：async_ui 文档包含 R10 迁移入口', () {
    final text = File('../../docs/extensions/async_ui.md').readAsStringSync();
    expect(text, contains('R10 迁移'));
    expect(text, contains('rules.R10: false'));
    expect(text, contains('w_tools:ignore R10'));
  });

  test('ASYNC-017：naming.md 登记 async 的 Snapshot 角色', () {
    final naming = File('../../docs/naming.md').readAsStringSync();

    expect(naming, contains('`Snapshot`'));
    expect(naming, contains('WAsyncPagedSnapshot'));
  });

  test('ASYNC-020：async CHANGELOG 标题在第一行', () {
    final log = File('../../packages/async/CHANGELOG.md').readAsStringSync();

    expect(log.split('\n').first, '# Changelog');
  });

  test('ASYNC-023：README 写明 tryAll 的失败与顺序语义', () {
    final readme = File('../../packages/async/README.md').readAsStringSync();

    expect(readme, contains('结果顺序与输入一致'));
    expect(readme, contains('onError'));
    expect(readme, contains('tryAll'));
  });

  test('ASYNC-024：WAsyncState.errorMessage 已移除并记录迁移', () {
    final module = File('../../docs/modules/async_module.md').readAsStringSync();
    final migration = File('../../docs/migrations/async-6.0.md').readAsStringSync();

    expect(module, isNot(contains('errorMessage')));
    expect(migration, contains('WAsyncState.errorMessage'));
    expect(migration, contains('移除'));
  });
}
