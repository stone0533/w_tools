# w_tools_device

设备验证小工具（模拟器为主）。**只读 + 点击**，不改 App 代码。

```bash
dart run w_tools_device:device list                 # 列出模拟器（含 udid / 状态）
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out /tmp/a.png
dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
dart run w_tools_device:device tap 200 840          # 用「设备坐标」点，自动换算
dart run w_tools_device:device drag 200 700 200 300
dart run w_tools_device:device type "hello"
```

依赖（一次性）：

- macOS + Xcode（模拟器 GUI 是 **Device Hub**，Xcode 27 起取代 Simulator.app）
- `brew install cliclick`（真 CGEvent 点击；`osascript click at` 点不到模拟器画面）
- 给运行它的宿主 App 开「辅助功能」与「屏幕录制」

坐标标定原理：截 DeviceHub 窗口 → 找最外层黑色机身（连通域）→ 内缩得到设备屏幕矩形 →
按设备分辨率换算成「设备坐标 ↔ 屏幕坐标」。结果缓存在 `~/.cache/w_tools_device/`，
窗口位置或尺寸变化时自动重算。
