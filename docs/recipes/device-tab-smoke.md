# Tab 型 App 的设备冒烟（示例）

这是 **Tab 型 App 的示例**，不是 `w_tools_cli:init` 生成物，也不属于 `w_tools_device` 的通用 API。

- 脚本示例：[`packages/device/example/tool/device_smoke.dart`](../../packages/device/example/tool/device_smoke.dart)
- 依赖：`dev_dependencies` 加 `w_tools_device`
- 默认假定：iOS 模拟器、5 个等宽底部 tab、tab bar 在屏幕 94% 高度、顶部标题区随 tab 变化

复制到项目后，按实际布局修改 `--tabs`、`y` 和 `--region`。Android 不使用这个等分 tab 假设，
直接用 `w_tools_device` 的 `--android` 命令。

```bash
dart run tool/device_smoke.dart --tabs=4 --device=<udid>
```

更通用的验证请直接用：

```bash
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
```
