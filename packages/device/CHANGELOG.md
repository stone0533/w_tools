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
