# 表单提交：校验 + loading + 结果提示

```dart
final form = WFormController();

Future<void> _submit() async {
  // 1) 先校验：错误显示在字段边框上（WForm 默认已开启）
  if (!form.validate()) return;

  // 2) 提交期间用 loading 锁住重复点击，结果用 toast 提示
  try {
    await WToast.runWithLoading(
      () => api.save(form.value),   // form.value 是 Map<String, dynamic>
      message: '提交中...',
      successMessage: '提交成功',
    );
  } catch (error) {
    // runWithLoading 已经弹过错误提示，这里只做业务侧收尾（日志 / 回滚）
    debugPrint('submit failed: $error');
  }
}

// 页面
WForm(
  controller: form,
  child: Column(
    children: [
      const WFormTextField(name: 'name', label: '姓名', message: '必填'),
      const WFormTextField(name: 'phone', label: '手机号'),
      FilledButton(onPressed: _submit, child: const Text('提交')),
    ],
  ),
);
```

要点：

- `form.validate()` 返回 bool；失败时字段边框变红并显示 message；
- 不要把“字段校验错误”再弹 toast——两处重复提示；
- `runWithLoading` 失败会先弹错误提示再 `rethrow`，所以 `catch` 里不要再弹一次；
- `WFormButton` 是字段值选择用的；普通“提交”按钮用 `FilledButton`（或 ui 包的 `WButton`）；
- 表单与 controller 一对一；页面销毁时不需要手动 dispose controller（无监听时），但不要跨页复用。
