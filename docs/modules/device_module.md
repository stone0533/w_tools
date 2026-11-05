# Device 模块文档

## 概述

`w_tools_device` 是**设备验证 CLI**（纯 Dart），用于 iOS/Android 模拟器、Android 真机与
iOS 真机的发现、截图、坐标标定、点击/拖拽、稳定性等待和坐标自检。

它不是 UI 库：消费方通过 `dart run w_tools_device:device ...` 使用；`lib/src/` 的导出只供
仓库内示例/测试，**不承诺库 API 稳定性**。

## 平台矩阵

| 平台 | list | shot | tap / drag / verify | type / size / wait | foreground |
| --- | --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ | ❌ |
| Android 模拟器 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Android 真机 | ✅ | ✅ | ✅（adb） | ✅ | ✅ |

## 命令

| 命令 | 说明 |
| --- | --- |
| `list` | 列出设备；`--real` 列 iOS 真机，`--android` 列 Android |
| `boot` | 启动 iOS 模拟器；省略参数时用第一台/已启动 |
| `shot` | 截图；`--real` / `--android` 切换来源 |
| `calibrate` | iOS 模拟器 DeviceHub 坐标标定 |
| `tap` | 点击；iOS 用设备坐标，Android 用截图像素 |
| `drag` | 拖拽；坐标体系同 `tap` |
| `type` | **实验**：输入文本（输入法/控制字符不可控） |
| `size` | 分辨率；iOS=point，Android=像素 |
| `foreground` | Android 前台包名 |
| `wait` | 等画面稳定 |
| `verify` | 点击并确认画面变化；可用 `--region` 限定区域 |

## 退出码

| 码 | 含义 |
| --- | --- |
| `0` | 成功 |
| `1` | `verify` 画面没变化（findings） |
| `2` | 参数 / 配置错误 |
| `3` | 外部不可用 / 超时 |
| `4` | 未分类执行错误 |

## 坐标与选项

- iOS 模拟器：`point`，通过 DeviceHub 窗口标定换算；`--scale` 可覆盖像素密度。
- Android：截图像素，不需要标定，也不需要 cliclick。
- `--out` 支持 `--out=/path` 与 `--out /path`。
- `--no-cache`、`--region`、`--timeout-ms`、`--stable-ms` 等按命令限制，详见 `--help`。
- 缓存目录：`~/.cache/w_tools_device/`；窗口移动/旋转后必要时加 `--no-cache`。

## 真机验证清单

CI 无法覆盖真实设备，发布前人工确认：

- [ ] iOS 模拟器：`list` / `boot` / `shot` / `calibrate` / `tap` / `verify`；
- [ ] DeviceHub 窗口移动或旋转后，`--no-cache` 能重新标定；
- [ ] Android 真机：`adb devices` 就绪，`shot` / `tap` / `size` / `foreground`；
- [ ] iOS 真机：`list --real` / `shot --real`，锁屏时能给出全黑 warning；
- [ ] 退出码 `0/1/2/3/4` 与 README / `--help` 一致。

## 相关

- 可运行示例：`packages/device/example/`
- CLI 手册：`packages/device/README.md`
- Agent 规则：`docs/agents/device-testing.md`
- Recipes：`docs/recipes/device-tab-smoke.md`、`keepalive-integration-test.md`、`e2e-login.md`
