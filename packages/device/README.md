# w_tools_device

设备验证小工具：**iOS/Android 模拟器可交互；Android 真机经 adb 可交互；iOS 真机只读（list / shot）**。工具本身不修改 App 业务代码。

| 平台 | list | shot | tap / drag / verify | type / size / wait | foreground |
| --- | --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ | ❌ |
| Android 模拟器 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Android 真机 | ✅ | ✅ | ✅（adb） | ✅ | ✅ |

> iOS 真机点击本工具不支持；安装 App 仍用 `flutter run` / Xcode / adb。Android 的 tap 坐标是截图像素。

## 安装

```yaml
dev_dependencies:
  w_tools_device: ^0.3.2
```

或：

```bash
dart pub add dev:w_tools_device
```

```bash
dart run w_tools_device:device list                 # 列出模拟器（含 udid / 状态）
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out=/tmp/a.png   # 也支持 --out /tmp/a.png；省略则生成唯一临时文件
dart run w_tools_device:device shot --real --device=<udid|名称>   # 真机截图（需解锁）
dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
dart run w_tools_device:device tap 200 840          # 用「设备坐标」点，自动换算
dart run w_tools_device:device drag 200 700 200 300
dart run w_tools_device:device type "hello"   # 实验：中文/emoji 取决于输入法；换行/控制字符会报错
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

选项：`--device=<udid|名称>`（也支持 `--device <值>`）、`--no-cache`（强制重标定）、
`--scale=3`（像素密度）、`--timeout-ms=15000`、`--stable-ms=600`、
`--region=x,y,w,h`（iOS 模拟器=设备坐标 point，Android=截图像素，只看这块区域）、
`--real`（iOS 真机：仅 list / shot）、`--json`（脚本/CI 用，结构化输出）、
`--version`（版本）、`--help`（帮助）。

平台 / 命令不兼容时会直接报错，例如：

```text
tap --real
boot --android
foreground（未加 --android）
size --real
--region 只用于 wait / verify
--out 只用于 shot
位置参数个数不对（如 tap 1 2 3、list x）
```

`--scale` 只用于 iOS 模拟器的 `calibrate` / `tap` / `drag` / `size` / `wait` / `verify`；必须是正整数。
传给它命令（如 `boot` / `type` / `shot`）会直接报错，而不是静默忽略。
`--no-cache` 只用于 iOS 模拟器的 tap / drag / verify；`wait --region` 不再依赖标定，因此不需要 `--no-cache`。
`--timeout-ms` 和 `--stable-ms` 只用于 wait / verify；`--out` 只用于 shot；`boot` 省略参数时用第一台/已启动模拟器。
Android 多台就绪且未指定 `--device`、或型号子串命中多台时会直接报错（exit 2）并列出 serial / model；
用 `--device=<serial|model>` 精确指定，不会静默把截图 / 点击打到另一台设备。
`--timeout-ms` 是等待上限：`wait` 只有一次窗口；`verify` 是点击前 + 点击后的**总预算**（不是各一份）。
`list` 不支持 `--device`；`type` 必须带文本，且属于实验命令（输入法/控制字符不可控）。
`--out` 支持 `--out=/path` 与 `--out /path` 两种写法；`--device` / `--region` / `--scale` /
`--timeout-ms` / `--stable-ms` 同样支持空格写法，空值会报错。

iOS 真机说明：列表/截图走 `devicectl`；**点击真机需要 idb 或 XCUITest，本工具不支持**。
锁屏/息屏时 `devicectl` 会返回全黑图，工具会给出 `warning`（`--json` 里也有）。

退出码：`0` 成功 · `1` `verify` 画面没变化（findings） · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误。
设备未启动、找不到指定设备、读不到 DeviceHub 窗口、命令超时都归 3；参数解析 / 组合校验失败归 2。

### `--json` 输出

所有 `--json` 输出都带 `schemaVersion: 1`、`ok`、`command` 和 `platform`
（`ios-simulator` / `ios-device` / `android`）；能定位到单台设备的命令还会带 `deviceId`
（udid 或 Android serial）。坐标类命令同时给出 `device`（输入坐标）与 `screen`（换算后的屏幕坐标；
Android 两者都是截图像素）。示例：

```json
{"schemaVersion":1,"ok":true,"command":"tap","platform":"ios-simulator","device":{"x":200,"y":840},"screen":{"x":200.5,"y":840.2},"deviceId":"AAAA"}
{"schemaVersion":1,"ok":false,"command":"tap","error":"找不到匹配的模拟器：nope（先 device list 确认）"}
```

依赖（一次性）：

- macOS + Xcode（模拟器 GUI 是 **Device Hub**，Xcode 27 起取代 Simulator.app）
- `brew install cliclick`（真 CGEvent 点击；`osascript click at` 点不到模拟器画面）
- 给运行它的宿主 App 开「辅助功能」与「屏幕录制」
- **Android 不需要** cliclick / 屏幕录制 / 标定：`adb` 的 `input tap` 直接用截图像素

### Android（adb）

```bash
dart run w_tools_device:device list --android          # 列设备（serial / model / state）
dart run w_tools_device:device size --android          # 分辨率（像素；有 Override size 时优先用它）
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
窗口位置 / 尺寸 / 设备宽高（`--scale` 变化）不同就会失效并重算；需要强制重算时用 `--no-cache`。

**横屏（Landscape）当前不支持**：`calibrate` 会明确提示切回 Portrait。
DeviceHub 的**缩放 / 侧栏布局变化不在标定缓存键里**：缩放或布局变化后先跑 `calibrate`，
或给 `tap` / `drag` / `verify` 加 `--no-cache`，否则可能复用旧 `deviceRect` 点偏。

## 库 API 边界

本包定位是 **CLI 工具**；`lib/src/` 的公开模块只供仓库内示例/测试使用，**不建议消费方依赖**。
消费方应使用 `dart run w_tools_device:device ...`，不要把 `package:w_tools_device/w_tools_device.dart`
当作稳定依赖。

这些导出仍受本包版本与 API 快照（`scripts/api_snapshots/`）校验：改名 / 删除会按 semver 抬版本，
不会静默漂移；CLI 才是稳定契约。

## 真机验证清单

CI 无法覆盖真实设备，发布前人工确认：

- [ ] iOS 模拟器：`list` / `boot` / `shot` / `calibrate` / `tap` / `verify` 可用；
- [ ] DeviceHub 窗口移动或旋转后，缓存能失效；必要时 `--no-cache` 能重新标定；
- [ ] Android 真机：`adb devices` 就绪，`shot` / `tap` / `size` / `foreground` 正常；
- [ ] iOS 真机：`list --real` / `shot --real` 正常，锁屏时能看到全黑 warning；
- [ ] 退出码 `0/1/2/3/4` 与 README / `--help` 一致；
- [ ] `--json` 的 `schemaVersion` / `platform` / `deviceId` 与本文一致。

## 示例

可运行示例见 [`example/`](example/)。
