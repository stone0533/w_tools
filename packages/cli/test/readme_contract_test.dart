import 'dart:io';

import 'package:test/test.dart';

void main() {
  final readme = File('README.md').readAsStringSync();

  test('DOC-001 README 写明 feedback search --gh 的退出码 3', () {
    expect(
      readme,
      contains('`feedback search --gh` 在 `gh` 未安装 / 未登录时同样退出 `3`，本地结果不返回。'),
    );
  });

  test('DOC-002 README 维护者写明新增包要同步的两份清单', () {
    expect(readme, contains('feedbackPackages'));
    expect(readme, contains('_examplePackages'));
    expect(readme, contains('test/internal/package_lists_test.dart'));
  });
}
