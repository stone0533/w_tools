# toast 使用规则（给人和 AI）

## 什么时候用

非阻塞的轻提示（成功 / 错误 / 警告 / loading）。确认框用 Flutter `showDialog`。

## 初始化（只做一次）

```dart
MaterialApp(
  builder: BotToastInit(),
  navigatorObservers: [BotToastNavigatorObserver()],
  ...
);
```

## 最小用法

```dart
WToast.showSuccess('保存成功');
WToast.showError('网络异常');

await WToast.runWithLoading(
  () => api.save(),
  message: '保存中...',
  successMessage: '保存成功',
  errorMessage: (e) => '保存失败：$e',
);
```

全局样式：

```dart
WToastTheme(style: WToastStyle.defaults.copyWith(...), child: MaterialApp(...));
WToast.showSuccess('ok', context: context);   // context 用来读 WToastTheme
```

## 不要用

- `WToastConfig`（弃用，用 `WToastStyle` + `WToast`）；
- Toast 做阻塞确认 / 表单校验错误展示（用对话框 / 字段错误）；
- 在 `main()` 顶层构造需要 Theme 的样式。

## 常见坑

- 忘记 `BotToastInit` 时所有入口静默失败（走 `onError`）；
- loading 全局唯一：再次 `showLoading` 会先关上一个；
- `runWithLoading` 失败会先提示再 `rethrow`，调用方仍要处理异常。

完整说明：[toast_module.md](../modules/toast_module.md) · 示例：`packages/toast/example`
