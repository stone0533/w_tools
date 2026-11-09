# 设备验证（w_tools_device）

需要模拟器 / Android / 真机截图、点击、稳定等待或 E2E 自动登录时先读本文，不要手写 adb / DeviceHub 标定。

## 平台支持

| 平台 | list | shot | tap / drag / verify | type / size / wait | foreground |
| --- | --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ | ❌ |
| Android 模拟器 / 真机 | ✅ | ✅ | ✅（adb） | ✅ | ✅ |

## 安装与命令

```bash
dart pub add dev:w_tools_device
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称>"        # 省略时用第一台/已启动
dart run w_tools_device:device shot --out=/tmp/shot.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device type "hello"        # 实验：输入法/控制字符不可控
dart run w_tools_device:device size                 # iOS=point，Android=像素
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
dart run w_tools_device:device wait --region=<x,y,w,h>
```

Android：

```bash
dart run w_tools_device:device list --android
dart run w_tools_device:device size --android
dart run w_tools_device:device shot --android --out=/tmp/shot.png
dart run w_tools_device:device tap --android <x> <y>
dart run w_tools_device:device drag --android <x1> <y1> <x2> <y2>
dart run w_tools_device:device type --android "hello"
dart run w_tools_device:device foreground --android
```

iOS 真机只读：

```bash
dart run w_tools_device:device list --real
dart run w_tools_device:device shot --real --device=<名称>
```

## 规则

- iOS 模拟器点击需要 cliclick + 辅助功能/屏幕录制；
- iOS 真机点击需要 idb/XCUITest，本工具不支持；
- Android 的 tap 坐标是截图像素，不需要标定；
- `--region`：iOS 模拟器是设备坐标（point），Android 是截图像素；
- `verify` 默认比较整屏，动画/轮播会误判，用 `--region`；
- `--scale` 只用于 iOS 模拟器 calibrate/tap/drag/size/wait/verify；
- `--no-cache` 只用于 iOS 模拟器 tap/drag/verify；`wait --region` 不需要标定，也不需要 `--no-cache`；
- `--timeout-ms` / `--stable-ms` 只用于 wait/verify；
- `--json` 输出带 `schemaVersion: 1`、`platform`、`deviceId`（单设备命令）；
- 退出码：`0` 成功 · `1` verify 没变化 · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误。
  设备未启动、找不到指定设备、读不到 DeviceHub 窗口、命令超时都归 `3`。

## 可选示例

- Tab 冒烟：[`packages/device/example/README.md`](../../packages/device/example/README.md)
- Keep-alive 集成测试：[`docs/recipes/keepalive-integration-test.md`](../recipes/keepalive-integration-test.md)
- E2E 免登录：[`docs/recipes/e2e-login.md`](../recipes/e2e-login.md)
