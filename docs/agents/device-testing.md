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

先读 [`packages/e2e/README.md`](../../packages/e2e/README.md)。

```dart
if (E2eConfig.fromEnvironment().canAutoLogin) {
  await E2eLogin.run(
    login: (email, password) => repository.login({'email': email, 'password': password}),
    afterLogin: () => Get.offAllNamed(Routes.NAV),
  );
}
```

```bash
flutter run -d <device> \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=qa@example.com \
  --dart-define=E2E_PASSWORD=secret
```

规则：

```text
E2E 只在非 release 生效
凭证只用于测试账号，不要复用真实密码
run() 失败返回 false，不阻塞启动
afterLogin 不阻塞 run 的结果
```

`init --device` 会生成 `docs/agents/device-testing.md` 和 `tool/device_smoke.dart`；
`tool/main_e2e.dart` 需要按 e2e README 手动创建。
