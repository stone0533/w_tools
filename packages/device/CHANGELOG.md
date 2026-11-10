# Changelog

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
