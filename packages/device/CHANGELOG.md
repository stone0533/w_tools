## 0.1.5

### Changed
- README 补「示例」小节，指向 `example/`。

## 0.1.4

### Changed
- 退出码统一：verify 没变化 2→1；参数/配置错误 2；外部/超时 3。

## 0.1.3

### Fixed
- `foreground --android` 取不到前台包名时现在退出 1，不再 `ok:true` 静默成功。
- `--scale` 增加命令白名单：只允许 calibrate/tap/drag/size/wait/verify，boot/type/shot 不再静默忽略。
- `type --android` 对空格/单引号做参数转义，换行/控制字符明确报错；补充中文/emoji 限制说明。
- 外部命令超时现在会 kill 子进程，避免 CI 残留 `adb` / `xcrun`。
- `shot --real` 支持位置参数作为 `--device` 的 fallback。
- 捕获 `FileSystemException` / 其他 Exception，输出统一错误而不是裸堆栈。

### Docs
- README 顶部拆开 iOS/Android 模拟器与真机支持矩阵：Android 真机经 adb 可交互，iOS 真机仅 list/shot。
- 修正“真机只读”的泛化表述，明确 `devicectl` / 点击限制只针对 iOS 真机。
- pubspec 描述与库注释同步；`--scale` 支持命令写清楚。

# Changelog

## 0.1.2

### Fixed
- 标定缓存现在会校验设备尺寸 / 方向 / `--scale`：旋转或换机型后不再复用旧 `deviceRect`（原先只比对窗口，可能静默点错坐标）。
- 外部命令（`xcrun` / `adb`）默认 120s 超时，卡死不再拖住 CI；`runBytes` 去掉依赖实现的 `Uint8List` cast。

## 0.1.1

### Fixed
- README 的 `shot --out` 示例改为 `--out=`；补充 `list --device` 与坐标体系说明。

## 0.1.0

- 初始版本：设备验证工具。
