# Keep-alive / TickerMode 集成测试

这是 **w_tools_ui 的参考示例**，不是 `init` 生成物，也不属于 `w_tools_device`。

- 示例文件：[`packages/ui/example/integration_test/app_keepalive_smoke_test.dart`](../../packages/ui/example/integration_test/app_keepalive_smoke_test.dart)
- 依赖：`dev_dependencies` 增加 `integration_test: {sdk: flutter}`
- 运行：

```bash
cd packages/ui/example
flutter test integration_test/app_keepalive_smoke_test.dart -d <device>
```

它验证的是：

1. `WKeepAliveWrapper`：切走再回来，State / 滚动位置保留；
2. 不可见页的 `TickerMode` 关闭。

注意：

- 示例里的 `_Harness` 是**固定页面结构**，不能替代你真实 App 的页面；
- 要验证自己的页面，应按同样思路写自己的 `integration_test`（真实入口 + 真实 Tab）；
- `w_tools_ui` 内部已有 `WKeepAliveWrapper` 的 widget 测试；这个示例只用于真实引擎/设备冒烟；
- `init --device` 只生成设备工具，不生成这个测试。

连接设备（mock）：

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // 用真实 App 入口替换 _Harness
}
```
