# w_tools_device 示例

本包是 CLI 工具，完整用法见 [`../README.md`](../README.md)。这里只放**可复制的命令片段**，
不是可独立运行的示例包（没有 `pubspec.yaml` / 测试 / 入口脚本）；坐标与前置条件请按项目实际环境修改。
不再提供 `device_smoke.dart` 这类「按某个 App 布局写死」的脚本。

## 只在会变的区域上做点击自检

整屏比较会被轮播 / 动画 / 时间戳干扰，用 `--region` 只看标题区（**与 tap 同坐标系**：iOS 是设备 point）：

```bash
# 先看设备坐标（point）与截图 px
dart run w_tools_device:device size --json

# 点第 3 个 tab，只比较顶部 40..120 pt
dart run w_tools_device:device verify 201 821 --region=0,40,402,80 --json
```

退出码：`0` 画面变了（点击生效）· `1` 画面没变（坐标可能失效）· `3` 等稳定超时。

## 用 shell 串一个最小冒烟

```bash
set -e
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out=/tmp/home.png
dart run w_tools_device:device tap 201 821
dart run w_tools_device:device wait --region=0,40,402,80 --timeout-ms=8000
```

Android 把上面每条加 `--android`，坐标换成 `size --android` 报告的截图像素。
