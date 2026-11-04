## 0.1.3

### Docs
- README 顶部拆开 iOS/Android 模拟器与真机支持矩阵：Android 真机经 adb 可交互，iOS 真机仅 list/shot。
- 修正“真机只读”的泛化表述，明确 `devicectl` / 点击限制只针对 iOS 真机。
- pubspec 描述与库注释同步。

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
