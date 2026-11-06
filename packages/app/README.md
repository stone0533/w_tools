# w_tools_app

`w_tools_app` 是 w_tools 的**应用启动契约层**，只包含与 GetX 无关的插件接口：

```dart
class AppServicePlugin extends WAppPlugin {
  @override
  String get name => 'app-service';

  @override
  Future<void> onInit() async {
    // 初始化
  }
}
```

需要完整的 `WApp` 启动器、GetX 路由、语言切换与底部弹窗时，依赖：

```yaml
dependencies:
  w_tools_app_getx: ^1.0.1
```

`w_tools_app_getx` 会 re-export 本包的 `WAppPlugin`。

## 历史迁移

升级前先看 [`docs/migrations/`](https://github.com/stone0533/w_tools/blob/main/docs/migrations/README.md)：
每个包的 breaking 变更都有「旧 → 新」对照，不只是变更清单。
