# 设备验证（w_tools_device）

> 项目：`{{projectName}}`
> 本文件由 `dart run w_tools_cli:w_tools init --device` 生成，只包含通用设备命令；项目自己的
> 设备、账号、tab 布局请写到项目文档，不要改这份通用说明。
> 完整参数以 [`packages/device/README.md`](https://github.com/stone0533/w_tools/blob/main/packages/device/README.md) 为准。

## 平台支持

| 平台 | list | shot | tap / drag / verify | foreground |
| --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ |
| Android 模拟器 / 真机 | ✅ | ✅ | ✅（adb） | ✅ |

## 安装

```bash
dart pub add dev:w_tools_device
```

## 常用命令

```bash
# 模拟器
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称>"
dart run w_tools_device:device shot --out=/tmp/shot.png
dart run w_tools_device:device calibrate
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
dart run w_tools_device:device wait --region=<x,y,w,h>

# iOS 真机（只读）
dart run w_tools_device:device list --real
dart run w_tools_device:device shot --real --device=<名称>

# Android（坐标 = 截图像素）
dart run w_tools_device:device list --android
dart run w_tools_device:device size --android
dart run w_tools_device:device shot --android --out=/tmp/shot.png
dart run w_tools_device:device tap --android <x> <y>
dart run w_tools_device:device foreground --android
```

## 注意事项

- iOS 模拟器点击需要 cliclick，并给宿主 App 开「辅助功能」+「屏幕录制」；
- iOS 真机只能 list/shot，点击需要 idb/XCUITest；
- Android 不需要 cliclick/标定，`tap` 坐标就是截图像素；
- 多台设备命中（模拟器 / 真机 / Android 型号子串）会报错并列出候选，用 `--device=` 精确指定；
- `verify` 默认比较整屏，动画/轮播会误判；用 `--region`（与 tap 同坐标系：iOS=设备 point，Android=截图像素）；
- `size --json` 的 `scale` / `scaleSource` 给出像素密度来源，不需要再传 `--scale`；
- 标定不缓存：`tap` / `drag` / `verify` 每次现算，DeviceHub 缩放后不会复用旧坐标；
- Device Hub 窗口里选中的设备必须与 `--device` 一致，否则 `calibrate` / `tap` 会报错（exit 3）；
- iOS 的 `tap` / `drag` 默认先释放宿主左键（`du:.`）；`--no-release-mouse` 可关闭预释放与
  `verify` 失败后的自动释放（需要保留进行中的拖拽时用）；
- 点击**全部**无效（tap 返回 0 但画面不动 / 模拟器像被长按）先查宿主左键是否卡住：
  `swift -e 'import CoreGraphics; print(CGEventSource.buttonState(.hidSystemState, button: .left))'`，
  用 `cliclick du:.` 释放；`verify` 没变化时 JSON 可能带 `mouseButtonDown` / `releasedMouse` / `hint`；
- 退出码：`0` 成功 · `1` verify 没变化 · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误。

## 可选 recipe

- 命令片段（Tab 冒烟等，不是 init 生成物）：
  <https://github.com/stone0533/w_tools/blob/main/packages/device/example/README.md>
- Keep-alive / TickerMode 集成测试：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/keepalive-integration-test.md>
- E2E 免登录：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/e2e-login.md>

## 项目自检清单

- [ ] 能列出至少一台已启动设备
- [ ] 能截图，且不是全黑
- [ ] 能用 `verify --region` 确认一次真实 UI 变化
- [ ] iOS 真机已解锁并信任；Android 已授权调试
