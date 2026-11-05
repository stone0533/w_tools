> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# form 5.1：多选占位不再默认 ALL

5.0 及以前，`WFormMultiDropdown` 在未配置 `hintText` 时显示 `ALL`；5.1 起不显示占位，
与 `WFormDropdown` 的行为一致（未配置 `hintText` 就不显示提示）。

如果你依赖旧文案，显式传回去即可：

```dart
WFormMultiDropdown(name: 'tags', hintText: 'ALL', items: ...)
```

建议改成业务文案：

```dart
WFormMultiDropdown(name: 'tags', hintText: '请选择标签', items: ...)
```

5.1 其余新增（`leading` / `actions` 补齐、`WFormController.reset()`）见
`packages/form/CHANGELOG.md`。
