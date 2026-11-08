import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w_tools.dart' as w;

/// 聚合包契约测试。
///
/// 确认 `package:w_tools/w_tools.dart` 能解析 6 个基础子包的公开类型
/// —— 任一子包的重导出出现命名冲突，本文件会直接编译失败。
/// `WConfig` 已在 core 3.0 删除；聚合入口的配置走 `WToken` / `WAssets` / `WLocaleConfig`。
///
/// 各能力的行为测试放在各自的包内（packages/<pkg>/test/），
/// 本文件不重复覆盖。
void main() {
  test('w_tools.dart 汇总 6 个基础子包的公开类型', () {
    expect(w.WToken, isNotNull); // core
    expect(w.WFormIcons, isNotNull); // form
    expect(w.WApiConfig, isNotNull); // api
    expect(w.WToast, isNotNull); // toast
    expect(w.WButton, isNotNull); // ui
    expect(w.WAsyncState<Object>, isNotNull); // async
  });
  test('w_tools.dart 只 re-export 6 个基础子包', () {
    // 根包没有 API 快照，re-export 的增删必须在这里被挡住。
    final source = File('lib/w_tools.dart').readAsStringSync();
    final exports = RegExp(
      r"^export 'package:(w_tools_[a-z_]+)/",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toList()..sort();
    expect(exports, [
      'w_tools_api',
      'w_tools_async',
      'w_tools_core',
      'w_tools_form',
      'w_tools_toast',
      'w_tools_ui',
    ]);
  });
  test('WToken 可配置 token 键名', () {
    final origin = w.WToken.tokenKey;
    w.WToken.tokenKey = 'umbrella_token';
    expect(w.WToken.tokenKey, 'umbrella_token');
    w.WToken.tokenKey = origin;
  });
}
