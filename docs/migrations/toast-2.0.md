# toast 2.0 迁移

`WToastConfig` 已删除：样式用不可变的 `WToastStyle`，调用用 `WToast` 静态方法。

```dart
final style = WToastStyle.defaults.copyWith(duration: const Duration(seconds: 3));
WToast.showSuccess('ok', style: style);
```
