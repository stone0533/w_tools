# form 8.1 迁移

## 1. `WFormFieldShell.readOnly` 默认 false

`WFormFieldShell.new` 的 `readOnly` 现在可以省略，默认 `false`：

```dart
// before
WFormFieldShell(name: 'x', readOnly: false, child: ...);

// after
WFormFieldShell(name: 'x', child: ...);
```

- 外层 `WForm(readOnly: true)` 仍然通过 `WFormReadOnlyScope` 强制只读，不受默认值影响。
- `readOnly` 只影响边框只读态和向下注入的只读作用域，不负责禁用子控件。
- 自定义字段的子控件自身 `enabled: false` 时仍需显式传 `readOnly: true`，否则边框不会显示只读态。
