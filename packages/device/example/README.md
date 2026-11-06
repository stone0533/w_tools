# w_tools_device 示例

`tool/device_smoke.dart` 是 **Tab 型 App** 的 iOS 模拟器冒烟示例，不是通用脚本，也不会由
`w_tools_cli:init` 自动生成。

它假定：

- iOS 模拟器已启动，App 已登录并在 tab 页前台；
- 底部 tab bar 在屏幕约 94% 高度，tab 等宽；
- 顶部 4%–12% 是标题区，切换 tab 会变化；
- 已安装 cliclick，宿主 App 有辅助功能/屏幕录制权限。

使用前把脚本复制到自己的项目，`dev_dependencies` 加 `w_tools_device`，并按实际布局修改
`--tabs`、`y`、`region`：

```bash
dart run tool/device_smoke.dart --tabs=4 --device=<udid>
```

更通用的验证（只比较会变的区域）直接用：

```bash
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
```

Android 不做这个等分 tab 假设；直接用 `w_tools_device` 的 `--android` 命令，见
[`../README.md`](../README.md)。
