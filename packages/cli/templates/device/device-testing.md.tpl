# 设备验证（w_tools_device）

> 项目：`{{projectName}}`
> 本文件由 `dart run w_tools_cli:init --device` 生成，只包含通用设备命令；项目自己的
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
- `verify` 默认比较整屏，动画/轮播会误判；用 `--region` 只看会变的区域；
- `--scale` 只用于 iOS 模拟器的 calibrate/tap/drag/size/wait/verify；
- 退出码：`0` 成功 · `1` 参数/执行错误 · `2` verify 没变化 · `3` wait 超时；
- 标定缓存：`~/.cache/w_tools_device/<udid>.json`。

## 可选 recipe

- Tab 型 App 的冒烟示例（不是 init 生成物）：
  <https://github.com/stone0533/w_tools/blob/main/packages/device/example/tool/device_smoke.dart>
- Keep-alive / TickerMode 集成测试：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/keepalive-integration-test.md>
- E2E 免登录：
  <https://github.com/stone0533/w_tools/blob/main/docs/recipes/e2e-login.md>

## 项目自检清单

- [ ] 能列出至少一台已启动设备
- [ ] 能截图，且不是全黑
- [ ] 能用 `verify --region` 确认一次真实 UI 变化
- [ ] iOS 真机已解锁并信任；Android 已授权调试
