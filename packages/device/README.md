# w_tools_device

设备验证小工具：**iOS 模拟器可交互；Android 模拟器 / 真机经 adb 可交互；iOS 真机只读（list / shot）**。工具本身不修改 App 业务代码。

| 平台 | list | shot | tap / drag / verify | size / wait | foreground |
| --- | --- | --- | --- | --- | --- |
| iOS 模拟器 | ✅ | ✅ | ✅ | ✅ | ❌ |
| iOS 真机 | ✅ | ✅ | ❌（需 idb / XCUITest） | ❌ | ❌ |
| Android 模拟器 / 真机 | ✅ | ✅ | ✅（adb） | ✅ | ✅ |

> 0.4.0 删除了 `type`（输入文本）：cliclick 的 `t:` 打到**当前焦点应用**，不保证进模拟器；
> 需要输入时用 `integration_test` 的 `enterText`，或手动输入。

## 安装

```yaml
dev_dependencies:
  w_tools_device: ^0.4.0
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
dart run w_tools_device:device size                 # iOS：point + 截图 px + 密度；Android：像素
dart run w_tools_device:device wait                 # 等画面稳定（默认 600ms 内不再变）
dart run w_tools_device:device verify 200 840       # 点一下并确认画面真的变了（坐标自检）
dart run w_tools_device:device verify 200 840 --region=0,40,402,80
                                                    # 只看标题区：局部变化才认，避开轮播/滚动
```

坐标体系：

```text
iOS 模拟器  tap / drag / verify 的输入 = 设备 point；--region 与 tap 同坐标系（point）
Android     全部是截图像素
iOS 真机    list / shot only
```

### 像素密度自动读取（不再需要 `--scale`）

`size` / `verify` 需要的「截图 px ÷ 设备 point」读模拟器的设备类型描述：

```text
~/Library/Developer/CoreSimulator/Devices/<udid>/device.plist  → deviceType（标识符）
xcrun simctl list devicetypes --json                            → identifier → bundlePath
<bundlePath>/Contents/Resources/capabilities.plist
    capabilities.ScreenDimensionsCapability: main-screen-width / height / scale
```

`device.plist` 里是标识符（`com.apple.CoreSimulator.SimDeviceType.iPhone-17`），
而 DeviceTypes 目录名是人类可读名（`iPhone 17.simdevicetype`），所以中间必须走
`simctl list devicetypes` 的 `bundlePath` 映射 —— 不能直接拼目录。

读不到（simctl 异常 / 旧版 Xcode）才回退到「截图尺寸 + 经验密度」（按宽高比区分 iPad / iPhone，含横屏），
并在 `--json` 里标 `scaleSource: "fallback"`，不会静默猜错。

`calibrate --json` 里：

- `deviceRect` 是**屏幕坐标**（point，已含窗口原点），`tap` / `drag` 直接使用；
- `windowTitle` 是标定时读到的窗口标题（例如 `iPhone 17 Pro – iOS 26.5`），用于核对设备；
- `window.scale` 是 DeviceHub 窗口截图的 px/point（Retina 通常 2）；
- `screenshot.scale` 是设备截图的 px/point（例如 1206/402 = 3）；
- 两套 scale 分开命名，不会混用。

标定**不缓存**：`tap` / `drag` / `verify` 每次都现场标定。这样 DeviceHub 缩放 / 侧栏布局变化后
不会复用旧 `deviceRect` 点偏（代价是每次多一次标定，约 0.5–1s）。

标定前会核对 Device Hub 的**窗口标题**：窗口里显示的不是 `--device` 指定的设备时直接报错（exit 3），
不会静默把点击打到另一台设备。标题读不到时跳过校验（兼容未来 Xcode）。

选项：`--device=<udid|名称>`（也支持 `--device <值>`）、`--timeout-ms=15000`、
`--stable-ms=600`、`--region=x,y,w,h`（**与 tap 同坐标系**：iOS 为设备 point，Android 为截图像素）、
`--no-release-mouse`（关闭 iOS 交互命令的宿主左键释放：点击前 + verify 失败后的自动释放，见下文排障）、
`--real`（仅 list / shot）、`--android`、`--json`（脚本 / CI 用）、`--version`、`--help`。

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

`--timeout-ms` 和 `--stable-ms` 只用于 wait / verify；`--out` 只用于 shot；`boot` 省略参数时用唯一匹配的模拟器。
多台设备命中（iOS 模拟器 / iOS 真机 / Android 型号子串）都会直接报错（exit 2）并列出候选，
用 `--device=<udid|serial>` 精确指定，不会静默把截图 / 点击打到另一台设备。

iOS 真机说明：列表/截图走 `devicectl`；**点击真机需要 idb 或 XCUITest，本工具不支持**。
锁屏/息屏时 `devicectl` 会返回全黑图，工具会给出 `warning`（`--json` 里也有）。
`list --real --json` 的 `state` 取自 `bootState`（缺失时回落 `tunnelState`），`transport` 缺失时
**省略该字段**（不会输出字符串 `"null"`）；文本表把 `state` 显示成中文（`已启动` / `不可用` 等），
JSON 仍保留 raw 值；`shot --real` 失败会带上 `state=unavailable` 之类的原文，`tunnelState=connected`
也会被当作可用。

退出码：`0` 成功 · `1` `verify` 画面没变化（findings） · `2` 参数/配置错误 · `3` 外部不可用 / 超时 · `4` 未分类执行错误。
设备未启动、找不到指定设备、读不到 DeviceHub 窗口、命令超时都归 3；参数解析 / 组合校验失败归 2。

### `--json` 输出

所有 `--json` 输出都带 `schemaVersion: 2`、`ok`、`command` 和 `platform`
（`ios-simulator` / `ios-device` / `android`），解析失败时也会带 `platform`；能定位到单台设备的命令还会带
`deviceId`（udid 或 Android serial）。坐标类命令同时给出 `device`（输入坐标）与 `screen`（换算后的屏幕坐标；
Android 两者都是截图像素）。

`ok` 只表示「命令是否按预期完成」：`verify` 画面没变化仍是 `ok:true` + 退出码 1（findings）；
`wait` 超时是 `ok:false` + 退出码 3。

`verify` / `wait` 同时给出 `region`（用户输入，与 tap 同坐标系）与 `regionPixels`（实际参与指纹比较的
截图 px）；`size` 回退时额外带 `scaleReason`（`no-device-type` / `no-devicetypes` /
`unknown-device-type` / `no-capabilities`），避免只知道「回退了」却不知道卡在哪一步。
`verify` 没变化时还可能带 `mouseButtonDown`（探针结果）与 `releasedMouse`（检测到左键按下并释放成功），
以及 `hint` 排查提示。

```json
{"schemaVersion":2,"ok":true,"command":"tap","platform":"ios-simulator","device":{"x":200,"y":840},"screen":{"x":200.5,"y":840.2},"deviceId":"AAAA"}
{"schemaVersion":2,"ok":false,"command":"tap","platform":"ios-simulator","error":"找不到匹配的模拟器：nope（先 device list 确认）"}
{"schemaVersion":2,"ok":true,"command":"verify","platform":"ios-simulator","changed":true,"region":{"x":0,"y":333,"w":402,"h":100},"regionPixels":{"x":0,"y":999,"w":1206,"h":300},"deviceId":"AAAA"}
```

依赖（一次性）：

- macOS + Xcode（模拟器 GUI 是 **Device Hub**，Xcode 27 起取代 Simulator.app）
- `brew install cliclick`（真 CGEvent 点击；`osascript click at` 点不到模拟器画面）
- 给运行它的宿主 App 开「辅助功能」与「屏幕录制」
- **Android 不需要** cliclick / 屏幕录制 / 标定：`adb` 的 `input tap` 直接用截图像素

### 点击全部无效时（宿主左键卡住）

症状：`tap` 返回 0 但模拟器没反应，`verify` 只报「画面无变化」，或者模拟器像被长按（图标抖动）。
通常是**宿主左键被留在按下状态**（手工 `cliclick dd:` 未释放、外部脚本中断等）。
检查与释放：

```bash
swift -e 'import CoreGraphics; print(CGEventSource.buttonState(.hidSystemState, button: .left))'
cliclick du:.
```

工具侧：`tap` / `drag` 默认会在点击前先发 `du:.`（在当前位置幂等释放，与点击串在同一次 cliclick 调用），
所以上一次中断留下的按下状态会被自动清掉；`drag` 的异常 / 超时路径还会再补一次释放。
需要保留一个进行中的拖拽、或完全不动鼠标时，用 `--no-release-mouse` 关闭预释放与 verify 自动释放。

`verify` 没变化时会读一次 `CGEventSource.buttonState`（仅此时调用 swift，约 0.2s）：
`mouseButtonDown` / `releasedMouse` 写进 JSON，并给对应的 hint。`swift` 不可用时字段省略，
不影响退出码。

### Android（adb）

```bash
dart run w_tools_device:device list --android          # 列设备（serial / model / state）
dart run w_tools_device:device size --android          # 分辨率（像素；有 Override size 时优先用它）
dart run w_tools_device:device shot --android --out=/tmp/a.png
dart run w_tools_device:device tap --android 540 1200  # **截图像素**
dart run w_tools_device:device drag --android 540 1600 540 800
dart run w_tools_device:device wait --android
dart run w_tools_device:device verify --android 540 300 --region=0,300,1080,1500
dart run w_tools_device:device foreground --android    # 前台包名（冒烟前置校验）
```

> Android 没有「窗口标定」这回事：`adb shell input tap <x> <y>` 直接吃屏幕像素，
> 所以 `tap`/`drag`/`verify --region` 的坐标一律是**截图像素**（用 `size --android` 看）。

标定原理：截 DeviceHub 窗口 → 找最外层黑色机身（连通域）→ 内缩得到设备屏幕矩形 →
按设备分辨率换算成「设备坐标 ↔ 屏幕坐标」。`deviceRect` 以屏幕坐标返回。

**横屏（Landscape）当前不支持**：`calibrate` 会明确提示切回 Portrait。

## 库 API 边界

本包定位是 **CLI 工具**：`lib/` 下只有 `src/`（内部实现），**没有公开 barrel**。
0.4.0 起 `package:w_tools_device/w_tools_device.dart` 已删除，也不再有公开 API 快照。

消费方应使用 `dart run w_tools_device:device ...`，不要依赖 `lib/src/**` 的类型；
内部类型改名 / 删除不承诺兼容。

## 真机验证清单

CI 无法覆盖真实设备，发布前人工确认：

- [ ] iOS 模拟器：`list` / `boot` / `shot` / `calibrate` / `tap` / `verify` 可用；
- [ ] `size --json` 的 `scale` / `scaleSource` 与模拟器实际分辨率一致（正常应为 `deviceType`）；
- [ ] DeviceHub 窗口移动或缩放后，`tap` 仍点在预期位置（每次现算标定）；
- [ ] Device Hub 里换成另一台设备后，`calibrate --device=<别的设备>` 会报标题不一致（exit 3）；
- [ ] Android 真机：`adb devices` 就绪，`shot` / `tap` / `size` / `foreground` 正常；
- [ ] iOS 真机：`list --real` / `shot --real` 正常，锁屏时能看到全黑 warning，不可用设备报 `state=`；
- [ ] 退出码 `0/1/2/3/4` 与 README / `--help` 一致；
- [ ] `--json` 的 `schemaVersion` / `platform` / `deviceId` 与本文一致。

## 示例

可运行片段见 [`example/`](example/)。
