import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/w.dart' as w;

/// 聚合包契约测试。
///
/// 确认 `package:w_tools/w.dart` 能解析 9 个子包的公开类型
/// —— 任一子包的重导出出现命名冲突，本文件会直接编译失败。
/// 根 `WConfig` 已移除，配置改用子包入口。
///
/// 各能力的行为测试放在各自的包内（packages/<pkg>/test/），
/// 本文件不重复覆盖。
void main() {
  test('w.dart 汇总 9 个子包的公开类型', () {
    expect(w.WFormDefaults, isNotNull); // form
    expect(w.WAppConfig, isNotNull); // app
    expect(w.WApiConfig, isNotNull); // api
    expect(w.WToast, isNotNull); // toast
    expect(w.WButton, isNotNull); // ui
    expect(w.WMap<Object>, isNotNull); // map
    expect(w.WQrView, isNotNull); // qr
    expect(w.WAsyncState<Object>, isNotNull); // async
  });
}
