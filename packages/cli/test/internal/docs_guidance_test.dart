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
}
