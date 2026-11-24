# Changelog

## 0.4.0

### Breaking
- 删除 `type` 命令：iOS 侧 cliclick 的 `t:` 打到**当前焦点应用**（很可能是终端），
  Android 侧输入法/控制字符不可控；输入请用 `integration_test` 的 `enterText`。
- 删除 `--scale`：设备像素密度改为读模拟器设备类型描述
  （`simctl list devicetypes` 的 `bundlePath` → `ScreenDimensionsCapability.main-screen-scale`），
  读不到才回退并把 `scaleSource` 标成 `fallback`。
- 设备选择统一：iOS 模拟器 / iOS 真机 / Android 都按「精确匹配优先、子串命中多台直接报错（exit 2）」，
  不再静默取第一台。
- 删除 `--no-cache` 与标定缓存：`tap` / `drag` / `verify` 每次现算（原因与代价见 Changed）。
- `--json` 升级到 `schemaVersion: 2`：删除 `real`、Android drag 的 legacy `from`/`to` 与重复的
  `screen` / `serial` / `android` 字段；错误 JSON 也带 `platform`；`wait` 超时改为 `ok:false`（退出码仍 3）。
- `size`（iOS）输出 point + 截图 px + `scale` + `scaleSource`；Android 不再输出重复的 `serial`（用 `deviceId`）。
- 删除 `example/tool/device_smoke.dart`：它不是通用脚本，却带着一套假 `dart` 测试夹具；
  Tab 冒烟改为 [`example/README.md`](example/README.md) 里的命令片段。
- 库不再提供 barrel：`lib/w_tools_device.dart` 删除，`lib/src/**` 只供包内测试，CLI 才是稳定契约。
  随之删除 / 收口的内部 API：`CalibrationStore`、`Calibration.fromJson`、`Calibration.matches`、
  `Adb.resolve`、`Adb.requirePackage`、`Adb.text`、`Adb.escapeTextArgument`、`Input.type`、
  `DeviceOptions.deviceOrFirst` / `seen` / `noCache` / `scale`、`Simctl.resolve` / `guessScale`、
  `RealDevice.resolve`、`AndroidDevice.product` / `transport`。
- `DeviceCliDeps`（6 个工厂闭包 + 全局可变 `_deps`）改为 `DeviceRuntime`（显式实例注入）。

### Changed
- `calibrate --json` 新增 `windowTitle`（标定时 Device Hub 窗口标题），便于核对标定的是哪台设备。
- `--region` **与 tap 同坐标系**（iOS 模拟器 = 设备 point，Android = 截图像素）；
  `wait --region` 不再依赖 DeviceHub 标定，但仍按同一坐标系使用。
- `verify` / `wait` 的 `--json` 增加 `regionPixels`（实际参与指纹比较的截图 px；`region` 仍是输入坐标）；
  `size` 回退时增加 `scaleReason`（`no-device-type` / `no-devicetypes` / `unknown-device-type` /
  `no-capabilities`），排障时能看出卡在哪一步。
- 标定不缓存：`tap` / `drag` / `verify` 每次现算（旧缓存会在 DeviceHub 缩放 / 侧栏布局变化后
  复用旧 `deviceRect` 静默点偏；代价是每次多一次标定，约 0.5–1s）。
- `shot`（模拟器 / Android）不再做全黑警告：深色界面是正常内容；只有 `shot --real` 保留该提示。
- 参数校验改为命令表驱动：位置参数个数、平台、选项亲和性定义在一处。
- 临时文件统一由 `tempPath` / `withTempFile` 管理；Android 指纹采样改为内存直取，不再每帧落盘。
- `ScreenFingerprint` 固定像素采样步长（去掉同名不同单位的 `step` 参数）。

### Fixed
- iOS 模拟器 `tap` / `drag` / `verify` 的 `deviceRect` 补回窗口原点（`screencapture -R` 截的是
  窗口局部图），修复 0.3.3 起「窗口不在 (0,0) 时点击整体偏移、且仍报成功」；`#145` 回归用例
  改为真实屏幕坐标，并新增「点击结果必须落在 `deviceRect` 内」断言。
- `size` / `verify` 的像素密度：`device.plist` 的 `deviceType` 是标识符，而 DeviceTypes 目录名是
  人类可读名（含空格），改为用 `simctl list devicetypes --json` 的 `bundlePath` 定位
  `capabilities.plist`。此前 `scaleSource` 永远 `fallback`，iPad 等非 3x 设备会算错 point 尺寸。
- 密度兜底按宽高比识别 iPad / 横屏：`1488×2266` 的 iPad mini 不再被宽度启发式判成 3x；
  横屏 iPhone（`2622×1206`）也不会再被误判成 2x。
- Device Hub 窗口标题校验容忍 `Simulator` / `模拟器` 后缀（部分 Xcode 会这样写），
  同时仍拒绝 `iPhone 17 Pro` 误配 `iPhone 17 Pro Max`。
- `list --real`：`transportType` / `bootState` 缺失时不再输出字符串 `"null"` 或空串；
  `state` 回落 `tunnelState`，空字段在 JSON 里省略；文本表把状态显示成中文（JSON 仍保留 raw）；
  `shot --real` 失败文案带 `state=` 原文，且 `tunnelState=connected` 也会被当作可用。
- `drag` 在异常 / 超时路径补发一次幂等 `du:`：cliclick 被 kill 时不会执行 args 末尾的 `du:`，
  否则宿主左键会留在按下状态，之后所有 `tap` 都被系统当成拖拽延续而静默失效。
- `tap` / `drag` 默认在点击前先发 `du:.`（当前位置释放，和点击串在同一次 cliclick 调用），
  自动清掉上一次中断留下的按键状态；新增 `--no-release-mouse` 关闭预释放与 `verify` 失败后的自动释放。
- `verify` 没变化时读一次 `CGEventSource.buttonState`（仅失败路径调用 swift）：若左键仍按下则
  尝试 `du:.` 释放，并在 JSON 输出 `mouseButtonDown` / `releasedMouse` 与对应 `hint`；
  探针 / 释放使用 5s 短超时，`swift` 挂起不再把命令拖到 120s。
- 指定一台存在但未启动的模拟器时，报「模拟器存在但未启动：…（先 device boot）」，
  不再误报「找不到匹配的模拟器」。
- `calibrate --json` 的 `screenshot.scale` 优先使用标定时读到的真实密度
  （`ScreenMetrics.scale` → `Calibration.deviceScale`）；非整除宽度不再因整数除法反推而偏差。
- Device Hub 窗口显示的设备与 `--device` 不一致时直接报错（exit 3），不再静默标定 / 点击另一台；
  「识别不到机身」的提示区分「被遮挡」与「窗口里选中的设备已关机 / 没有实时预览」，并附窗口标题。

## 0.3.3

### Fixed
- iOS 模拟器 `tap` / `drag` 的 `deviceRect` 统一为屏幕坐标，`toScreen` 不再重复叠加
  `window.x/y`；窗口不在 `(0,0)` 时内容区不再整体偏移。
- calibration 缓存增加 `coordinateSpace` / `calibrationVersion`；旧缓存自动失效。
- `calibrate --json` 区分 `window.scale`（窗口截图 px/point）与 `screenshot.scale`
  （设备截图 px/point），并保留 `screenshot.windowScale`。

### Tests
- 增加窗口 `(40,107)` 的 #145 回归坐标：`tap 33 248` → `(422.746, 351.339)`。
- 增加旧 calibration 缓存不命中、`calibrate --json` 两套 scale 字段的测试。

## 0.3.2

### Changed
- Android 多台就绪且未指定 `--device`、或型号子串命中多台时，直接报错（exit 2）并列出
  serial / model；不再静默取第一台。`--device=<serial>` 仍可精确选中。

### Fixed
- `example/tool/device_smoke.dart`：重试成功后不再残留 `ok:false` 步骤；失败文案改为
  「期望退出码 / 实际退出码」。

## 0.3.1

### Fixed
- 横屏（Landscape）预览：`calibrate` / `tap` / `verify` 现在明确报
  “当前版本不支持旋转设备，请切回 Portrait”，不再误报“设备预览被其它窗口遮挡”。

### Docs
- 说明 DeviceHub 缩放 / 侧栏布局变化不在标定缓存键里：缩放后先 `calibrate`，或给
  `tap` / `drag` / `verify` 加 `--no-cache`。

## 0.3.0

### Breaking
- 删除 `CalibrationStore.isFresh`（实例方法）：改用 `CalibrationStore.isFreshCalibration(store.load(udid), window, deviceWidth: ..., deviceHeight: ...)`。
- 删除 `Stability.changedAfter`：`verify` 的稳定等待已内聚到 `TapVerifier`，超时抛 `VerificationTimeout`。
- `Stability.timeout`：旧 API 快照里由 `changedAfter` 的 `timeout` 参数误提取的伪条目，随 `changedAfter` 删除而消失；没有真实成员需要迁移。
- `CalibrationStore.isFreshCalibration` 去掉从未生效的 `scale` 参数；设备宽高（旋转 / `--scale`）已由宽高判定。
- `DeviceOptions.deviceOrFirst` 标记废弃，改用 `deviceQuery`；CLI 内部不再使用旧名。

### Changed
- 退出码分类：设备未启动 / 找不到指定设备 / 读不到 DeviceHub / 命令超时统一为 `3`；参数与组合校验仍为 `2`。
- `--json` 在参数解析失败时也输出 JSON；所有 JSON 增加 `schemaVersion: 1` 与 `platform`，单设备命令增加 `deviceId`。
- `--device` / `--region` / `--scale` / `--timeout-ms` / `--stable-ms` 支持空格写法；空值报错；位置参数数量按命令校验。
- `wait --region` 不再依赖 DeviceHub 标定；`--no-cache` 只用于 `tap` / `drag` / `verify`。
- 标定缓存命中不再激活 DeviceHub 窗口；只有真正需要重算时才截图。
- 整屏截图指纹改为解码像素采样，避免同一画面因 PNG 压缩 / 元数据差异被误判为变化。
- `verify` 点击前 / 后的稳定等待超时会明确失败（退出码 `3`），不再把「不稳定」误报成「没变化」；`--timeout-ms` 改为点击前 + 后的总预算。
- `shot`（模拟器 / 真机 / Android）统一生成唯一临时文件；模拟器 `shot` 也做全黑截图检查。
- `Adb.resolve` 只返回就绪设备；`size --android` 在存在 `Override size` 时优先使用它。
- `-h` / `--help` 只在第一个参数生效；新增 `--version`。
- `foreground --android` 取不到前台包名时退出码为 `3`（此前文档写 `1`、实现为 `2`）。

### Added
- `DeviceOptions.deviceQuery`（替代 `deviceOrFirst`）。
- `VerificationTimeout`（`verify` 稳定等待超时）。
- `--version`。
- JSON 中的 `platform` / `deviceId`；drag 增加 `device` / `screen` 坐标对象（旧 `from` / `to` 保留）。

## 0.2.0

### Added
- `--out` 支持 `--out <path>` 空格写法（仍支持 `--out=<path>`）。

### Changed
- 未分类执行错误退出码 1→4，与 verify findings（1）/ 参数（2）/ 外部或超时（3）区分。
- README / `--help` 同步平台矩阵、完整命令表、实验命令 `type`、`boot` 默认设备与真机验证清单。

## 0.1.5

### Changed
- README 补「示例」小节，指向 `example/`。

## 0.1.4

### Changed
- 退出码统一：verify 没变化 2→1；参数/配置错误 2；外部/超时 3。

## 0.1.3

### Fixed
- `foreground --android` 取不到前台包名时现在退出 3，不再 `ok:true` 静默成功。
- `--scale` 增加命令白名单：只允许 calibrate/tap/drag/size/wait/verify，boot/type/shot 不再静默忽略。
- `type --android` 对空格/单引号做参数转义，换行/控制字符明确报错；补充中文/emoji 限制说明。
- 外部命令超时现在会 kill 子进程，避免 CI 残留 `adb` / `xcrun`。
- `shot --real` 支持位置参数作为 `--device` 的 fallback。
- 捕获 `FileSystemException` / 其他 Exception，输出统一错误而不是裸堆栈。

### Docs
- README 顶部拆开 iOS/Android 模拟器与真机支持矩阵：Android 真机经 adb 可交互，iOS 真机仅 list/shot。
- 修正“真机只读”的泛化表述，明确 `devicectl` / 点击限制只针对 iOS 真机。
- pubspec 描述与库注释同步；`--scale` 支持命令写清楚。

## 0.1.2

### Fixed
- 标定缓存现在会校验设备尺寸 / 方向 / `--scale`：旋转或换机型后不再复用旧 `deviceRect`（原先只比对窗口，可能静默点错坐标）。
- 外部命令（`xcrun` / `adb`）默认 120s 超时，卡死不再拖住 CI；`runBytes` 去掉依赖实现的 `Uint8List` cast。

## 0.1.1

### Fixed
- README 的 `shot --out` 示例改为 `--out=`；补充 `list --device` 与坐标体系说明。

## 0.1.0

- 初始版本：设备验证工具。
