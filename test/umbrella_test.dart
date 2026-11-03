import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w_tools.dart' as w;

/// 聚合包契约测试。
///
/// 确认 `package:w_tools/w_tools.dart` 能解析 9 个子包的公开类型
/// —— 任一子包的重导出出现命名冲突，本文件会直接编译失败。
/// 根 `WConfig` 兼容层已移除；聚合入口导出的是 `core.WConfig`（仅 token 键名）。
///
/// 各能力的行为测试放在各自的包内（packages/<pkg>/test/），
/// 本文件不重复覆盖。
void main() {
  test('w_tools.dart 汇总 9 个子包的公开类型', () {
    expect(w.WConfig, isNotNull); // core.WConfig
    expect(w.WFormIcons, isNotNull); // form
    expect(w.WAppConfig, isNotNull); // app
    expect(w.WApiConfig, isNotNull); // api
    expect(w.WToast, isNotNull); // toast
    expect(w.WButton, isNotNull); // ui
    expect(w.WMap<Object>, isNotNull); // map
    expect(w.WQrView, isNotNull); // qr
    expect(w.WAsyncState<Object>, isNotNull); // async
  });
  test('WToken 可配置 token 键名（WConfig 同名字段为弃用代理）', () {
    final origin = w.WToken.tokenKey;
    w.WToken.tokenKey = 'umbrella_token';
    expect(w.WToken.tokenKey, 'umbrella_token');
    w.WToken.tokenKey = origin;
  });
}
