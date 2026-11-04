# w_tools_device

设备验证小工具：**iOS/Android 模拟器可交互；Android 真机经 adb 可交互；iOS 真机只读（list / shot）**。工具本身不修改 App 业务代码。

| 平台 | list | shot | tap / drag / verify | foreground |
| --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ |
| Android 模拟器 | ✅ | ✅ | ✅ | ✅ |
| Android 真机 | ✅ | ✅ | ✅（adb） | ✅ |

> iOS 真机点击本工具不支持；安装 App 仍用 `flutter run` / Xcode / adb。Android 的 tap 坐标是截图像素。

## 安装

```yaml
dev_dependencies:
  w_tools_device: ^0.1.4
```

或：

```bash
dart pub add dev:w_tools_device
```

```bash
dart run w_tools_device:device list                 # 列出模拟器（含 udid / 状态）
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out=/tmp/a.png   # 必须用 =；也可省略，自动生成唯一临时文件
dart run w_tools_device:device shot --real --device=<udid|名称>   # 真机截图（需解锁）
dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
dart run w_tools_device:device tap 200 840          # 用「设备坐标」点，自动换算
dart run w_tools_device:device drag 200 700 200 300
dart run w_tools_device:device type "hello"   # 中文/emoji 取决于设备输入法；换行/控制字符会报错
dart run w_tools_device:device size                 # 设备尺寸（iOS=point，直接读截图；Android=像素）
dart run w_tools_device:device wait                 # 等画面稳定（默认 600ms 内不再变）
dart run w_tools_device:device verify 200 840       # 点一下并确认画面真的变了（坐标自检）
dart run w_tools_device:device verify 200 840 --region=0,40,402,80
                                                    # 只看标题区：局部变化才认，避开轮播/滚动
```

坐标体系：

```text
iOS 模拟器  point
Android     截图像素
iOS 真机    list / shot only
```

选项：`--device=<udid|名称>`、`--no-cache`（强制重标定）、`--scale=3`（像素密度）、
`--timeout-ms=15000`、`--stable-ms=600`、`--region=x,y,w,h`（设备坐标，只看这块区域）、
`--real`（iOS 真机：仅 list / shot）、`--json`（脚本/CI 用，结构化输出）。

平台 / 命令不兼容时会直接报错，例如：

```text
tap --real
boot --android
foreground（未加 --android）
size --real
--region 只用于 wait / verify
--out 只用于 shot
```

`--scale` 只用于 iOS 模拟器的 `calibrate` / `tap` / `drag` / `size` / `wait` / `verify`；必须是正整数。
传给它命令（如 `boot` / `type` / `shot`）会直接报错，而不是静默忽略。
`--no-cache` 只用于 iOS 模拟器的 tap / drag / wait / verify（wait 需同时有 `--region`）；
`--timeout-ms` 和 `--stable-ms` 只用于 wait / verify；`--out` 只用于 shot。
`list` 不支持 `--device`；`type` 必须带文本。
`--out` 必须写成 `--out=/path`，不能写成 `--out /path`。

iOS 真机说明：列表/截图走 `devicectl`；**点击真机需要 idb 或 XCUITest，本工具不支持**。
锁屏/息屏时 `devicectl` 会返回全黑图，工具会给出 `warning`（`--json` 里也有）。

退出码：`0` 成功 · `1` `verify` 画面没变化（findings） · `2` 参数/配置错误 · `3` 外部不可用 / 超时。

依赖（一次性）：

- macOS + Xcode（模拟器 GUI 是 **Device Hub**，Xcode 27 起取代 Simulator.app）
- `brew install cliclick`（真 CGEvent 点击；`osascript click at` 点不到模拟器画面）
- 给运行它的宿主 App 开「辅助功能」与「屏幕录制」
- **Android 不需要** cliclick / 屏幕录制 / 标定：`adb` 的 `input tap` 直接用截图像素

### Android（adb）

```bash
dart run w_tools_device:device list --android          # 列设备（serial / model / state）
dart run w_tools_device:device size --android          # 分辨率（像素）
dart run w_tools_device:device shot --android --out=/tmp/a.png
dart run w_tools_device:device tap --android 540 1200  # **截图像素**
dart run w_tools_device:device drag --android 540 1600 540 800
dart run w_tools_device:device type --android "hello"
dart run w_tools_device:device wait --android
dart run w_tools_device:device verify --android 540 300 --region=0,300,1080,1500
dart run w_tools_device:device foreground --android    # 前台包名（冒烟前置校验）
```

> Android 没有「窗口标定」这回事：`adb shell input tap <x> <y>` 直接吃屏幕像素，
> 所以 `tap`/`drag`/`verify --region` 的坐标一律是**截图像素**（用 `size --android` 看）。

坐标标定原理：截 DeviceHub 窗口 → 找最外层黑色机身（连通域）→ 内缩得到设备屏幕矩形 →
按设备分辨率换算成「设备坐标 ↔ 屏幕坐标」。结果缓存在 `~/.cache/w_tools_device/`，
窗口位置或尺寸变化时自动重算；旋转设备后缓存不一定能自动识别，必要时用 `--no-cache`。
