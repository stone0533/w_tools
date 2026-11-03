# w_tools_device

设备验证小工具（模拟器为主）。**只读 + 点击**，不改 App 代码。

```bash
dart run w_tools_device:device list                 # 列出模拟器（含 udid / 状态）
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out /tmp/a.png
dart run w_tools_device:device shot --real --device=<udid|名称>   # 真机截图（需解锁）
dart run w_tools_device:device calibrate            # 标定 DeviceHub 里设备屏幕的坐标
dart run w_tools_device:device tap 200 840          # 用「设备坐标」点，自动换算
dart run w_tools_device:device drag 200 700 200 300
dart run w_tools_device:device type "hello"
dart run w_tools_device:device wait                 # 等画面稳定（默认 600ms 内不再变）
dart run w_tools_device:device verify 200 840       # 点一下并确认画面真的变了（坐标自检）
dart run w_tools_device:device verify 200 840 --region=0,40,402,80
                                                    # 只看标题区：局部变化才认，避开轮播/滚动
```

选项：`--device=<udid|名称>`、`--no-cache`（强制重标定）、`--scale=3`（像素密度）、
`--timeout-ms=15000`、`--stable-ms=600`、`--region=x,y,w,h`（设备坐标，只看这块区域）、
`--real`（真机：仅 list / shot）、`--json`（脚本/CI 用，结构化输出）。

真机说明：列表/截图走 `devicectl`；**点击真机需要 idb 或 XCUITest，本工具不支持**。
锁屏/息屏时 `devicectl` 会返回全黑图，工具会给出 `warning`（`--json` 里也有）。

退出码：`0` 成功 · `1` 参数/执行错误 · `2` `verify` 点下去画面没变化（坐标可能失效）。

依赖（一次性）：

- macOS + Xcode（模拟器 GUI 是 **Device Hub**，Xcode 27 起取代 Simulator.app）
- `brew install cliclick`（真 CGEvent 点击；`osascript click at` 点不到模拟器画面）
- 给运行它的宿主 App 开「辅助功能」与「屏幕录制」

坐标标定原理：截 DeviceHub 窗口 → 找最外层黑色机身（连通域）→ 内缩得到设备屏幕矩形 →
按设备分辨率换算成「设备坐标 ↔ 屏幕坐标」。结果缓存在 `~/.cache/w_tools_device/`，
窗口位置或尺寸变化时自动重算。
