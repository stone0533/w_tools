# 设备验证（w_tools_device）

需要模拟器 / Android / 真机截图、点击、稳定等待或 E2E 自动登录时先读本文，不要手写 adb / DeviceHub 标定。

## 平台支持

| 平台 | list | shot | tap / drag / verify | size / wait | foreground |
| --- | --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ | ❌ |
| Android 模拟器 / 真机 | ✅ | ✅ | ✅（adb） | ✅ | ✅ |

`type`（输入文本）在 0.4.0 删除：cliclick 打到当前焦点应用，不保证进模拟器；输入用
`integration_test` 的 `enterText`。

## 安装与命令

```bash
dart pub add dev:w_tools_device
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称>"        # 省略时用唯一匹配的模拟器
dart run w_tools_device:device shot --out=/tmp/shot.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device size                 # iOS=point + 截图 px；Android=像素
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
dart run w_tools_device:device foreground --android
```

iOS 真机只读：

```bash
dart run w_tools_device:device list --real
dart run w_tools_device:device shot --real --device=<名称>
```

## 规则

- iOS 模拟器点击需要 cliclick + 辅助功能/屏幕录制；
- 点击**全部**无效（tap 返回 0 但画面不动 / 模拟器像被长按）先查宿主左键是否卡在按下状态：
  `swift -e 'import CoreGraphics; print(CGEventSource.buttonState(.hidSystemState, button: .left))'`，
  用 `cliclick du:.` 释放；`tap` / `drag` 默认会先 `du:.`，`--no-release-mouse` 可关闭预释放与 verify 自动释放；
  `verify` 无变化时会探针并尝试释放，JSON 带 `hint` / `mouseButtonDown`（可能还有 `releasedMouse`）；
- iOS 真机点击需要 idb/XCUITest，本工具不支持；
- Android 的 tap 坐标是截图像素，不需要标定；
- 设备选择：iOS 模拟器 / 真机 / Android 都「精确匹配优先」；子串命中多台直接 exit 2 并列出候选，
  用 `--device=<udid|serial>` 指定，不会静默取第一台；
- `--region` **与 tap 同坐标系**（iOS 模拟器 = 设备 point，Android = 截图像素）；
- iOS 模拟器的 `deviceRect` 是屏幕坐标（已含窗口原点）；`calibrate --json` 的 `windowTitle`
  可与 `--device` 比对；窗口里选中的不是目标设备时 `calibrate` / `tap` / `verify` 会直接报错（exit 3）；
- 标定不缓存：`tap` / `drag` / `verify` 每次现算，DeviceHub 缩放 / 侧栏变化后不会复用旧坐标；
- `verify` 默认比较整屏，动画/轮播会误判，用 `--region`；
- `size --json` 的 `scale` / `scaleSource` 说明像素密度的来源（`deviceType` 走
  `simctl list devicetypes` 的 `bundlePath`；读不到才是 `fallback`）；
- iOS 真机 `list --real --json` 的 `state` 缺失时回落 `tunnelState`，`transport` 缺失时省略字段
  （不是字符串 `"null"`）；`shot --real` 失败会带 `state=` 原文；
- 横屏（Landscape）当前不支持（`calibrate` 会提示切回 Portrait）；
- `--timeout-ms` / `--stable-ms` 只用于 wait/verify；verify 的 `--timeout-ms` 是点击前 + 后的总预算；
- `--json` 带 `schemaVersion: 2`、`platform`、`deviceId`（单设备命令）；`verify` / `wait` 同时给出
  `region`（输入）与 `regionPixels`（实际比较的截图 px），`size` 回退时带 `scaleReason`；
  `ok` 表示命令是否完成：`verify` 没变化是 `ok:true` + 退出码 1，`wait` 超时是 `ok:false` + 退出码 3；
- 退出码：`0` 成功 · `1` verify 没变化 · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误。
  设备未启动、找不到指定设备、读不到 DeviceHub 窗口、命令超时都归 `3`。

## 可选示例

- 命令片段：[`packages/device/example/README.md`](../../packages/device/example/README.md)
- Keep-alive 集成测试：[`docs/recipes/keepalive-integration-test.md`](../recipes/keepalive-integration-test.md)
- E2E 免登录：[`docs/recipes/e2e-login.md`](../recipes/e2e-login.md)
