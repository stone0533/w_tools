import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w.dart' as w;

/// 聚合包契约测试。
///
/// 这里只做两件事：
/// 1. 确认 `package:w_tools/w.dart` 能解析 8 个子包的公开类型
///    —— 任一子包的重导出出现命名冲突，本文件会直接编译失败；
/// 2. 确认根 `WConfig` 兼容层仍代理到子包的配置类。
///
/// 各能力的行为测试放在各自的包内（packages/<pkg>/test/），
/// 本文件不重复覆盖。
void main() {
  test('w.dart 汇总 8 个子包的公开类型', () {
    expect(w.WConfig, isNotNull); // 根兼容层
    expect(w.WFormDefaults, isNotNull); // form
    expect(w.WAppConfig, isNotNull); // app
    expect(w.WApiConfig, isNotNull); // api
    expect(w.WToast, isNotNull); // toast
    expect(w.WButton, isNotNull); // ui
    expect(w.WMap<Object>, isNotNull); // map
    expect(w.WQrView, isNotNull); // qr
  });

  test('WConfig 代理 core 的 token 键名', () {
    final origin = w.WConfig.tokenKey;
    w.WConfig.tokenKey = 'umbrella_token';
    expect(w.WConfig.tokenKey, 'umbrella_token');
    w.WConfig.tokenKey = origin;
  });

  test('WConfig.assetImagePath 与 ui 的 WAssets 是同一个开关', () {
    final origin = w.WConfig.assetImagePath;
    w.WConfig.assetImagePath = 'assets/umbrella/';
    expect(w.WAssets.imagePath, 'assets/umbrella/');
    w.WConfig.assetImagePath = origin;
    expect(w.WAssets.imagePath, 'assets/images/');
  });
}
