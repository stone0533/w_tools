# 设备验证（w_tools_device / w_tools_e2e）

## 什么时候用

```text
需要在模拟器 / Android / 真机上截图、点击、等稳定、验证坐标
需要 E2E 测试账号自动登录
```

## 安装

```yaml
dev_dependencies:
  w_tools_device: ^0.1.0
  w_tools_e2e: ^0.1.0
```

```bash
dart pub add dev:w_tools_device
flutter pub add dev:w_tools_e2e
```

`w_tools_device` 是纯 Dart CLI；`w_tools_e2e` 是 Flutter 库。

> 支持矩阵：iOS 模拟器可 list/shot/tap/drag/verify；iOS 真机仅 list/shot（点击需 idb/XCUITest，本工具不支持）；
> Android 模拟器/真机走 adb，可 list/shot/tap/drag/verify/foreground。


## device

先读 [`packages/device/README.md`](../../packages/device/README.md)。

最小流程：

```bash
dart run w_tools_device:device list
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out=/tmp/shot.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device verify <x> <y> --region=x,y,w,h
```

规则：

```text
iOS 模拟器：设备坐标（point），需要 DeviceHub + cliclick + 辅助功能/屏幕录制
Android：截图像素，adb 直接 tap，不需要标定
真机：只支持 list / shot，点击需 idb / XCUITest
坐标不生效时先用 verify --region 自检，再考虑 --no-cache
```

## e2e

`w_tools_e2e` 只放在 `tool/main_e2e.dart`，**不要 import 到 `lib/main.dart`**。

推荐结构：

```text
lib/main.dart              → bootstrap()，不 import w_tools_e2e
lib/app/bootstrap.dart     → 提供 afterStart 钩子
tool/main_e2e.dart         → 唯一 import w_tools_e2e 的入口
```

`lib/main.dart`：

```dart
import 'app/bootstrap.dart';

Future<void> main() => bootstrap();
```

`lib/app/bootstrap.dart`：

```dart
import 'dart:async';

typedef AfterStart = FutureOr<void> Function();

Future<void> bootstrap({AfterStart? afterStart}) async {
  await initializeApp();
  await afterStart?.call();
}
```

`tool/main_e2e.dart`：

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_app/app/bootstrap.dart';
import 'package:my_app/app/router.dart';
import 'package:my_app/features/auth/auth_repository.dart';
import 'package:w_tools_e2e/w_tools_e2e.dart';

Future<void> main() async {
  await bootstrap(
    afterStart: () async {
      final config = E2eConfig.fromEnvironment();

      if (!config.canAutoLogin) {
        debugPrint('[E2E] skipped: missing E2E=1 / email / password');
        return;
      }

      final ok = await E2eLogin.run(
        config: config,
        login: (email, password) async {
          await AuthRepository.instance.login(email, password);
        },
        afterLogin: () async {
          await AppRouter.instance.goHome();
        },
        onError: (error, stack) async {
          debugPrint('[E2E] error: $error\n$stack');
        },
      );

      debugPrint('[E2E] login ok: $ok');
    },
  );
}
```

运行：

```bash
flutter run -d <device> -t tool/main_e2e.dart \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

规则：

```text
E2E 只在非 release 生效
凭证只用于测试账号，不要复用真实密码
run() 返回 false：未启用 / 缺账号密码 / 登录失败 / 超时
afterLogin 不阻塞 run()，不要在 run 返回后立刻断言页面
onError 可同步或异步；回调自身抛错不会让 run 抛出
```

集成测试要等待页面：

```dart
testWidgets('E2E auto login reaches home', (tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.text('Home'), findsOneWidget);
});
```

`init --device` 会生成 `docs/agents/device-testing.md` 和 `tool/device_smoke.dart`；
`tool/main_e2e.dart` 需手动创建。完整宿主接入片段见
[`packages/e2e/example/README.md`](../../packages/e2e/example/README.md)。
