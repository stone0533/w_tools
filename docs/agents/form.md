# Form 使用规则

新页面默认使用 `WForm` + 直接字段（`WFormTextField` / `WFormDropdown` 等），
不要从 `Config.build` 开始写。

```dart
WForm(
  controller: form,
  // 跟随明暗与品牌色；standard() 是显式浅色预设，只适合固定浅色页
  borderConfig: WFormBorderConfig.fromTheme(Theme.of(context)),
  fieldStyle: const WFormFieldStyle(height: 52),
  validatorSettings: WFormValidatorSettings()
    ..showBorderError = true,
  child: Column(
    children: [
      WFormTextField(
        name: 'email',
        label: '邮箱',
        message: '请输入邮箱',
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入邮箱';
          return null;
        },
      ),
      WFormDropdown<String>(
        name: 'country',
        label: '国家 / 地区',
        items: const {
          'CN': '中国大陆',
          'HK': '中国香港',
        },
      ),
    ],
  ),
)
```

规则：

1. 页面容器用 `WForm`，字段直接用 `WFormTextField` / `WFormDropdown` /
   `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` /
   `WFormRadioGroup` / `WFormButton`。
2. 直接字段不接受 `config` 参数；不要写 `WFormTextField(config: ...)`。
3. 不要用 `WFormTextFieldConfig().build(...)`；`WFormTextFieldCore` 等 `*Core`
   已内部化，不导出。
4. 页面级高度 / 内边距 / 文本样式用 `WForm.fieldStyle`（`WFormFieldStyle`）。
5. 字段级差异用直接参数，例如：
   - 文本：`label` / `message` / `validator` / `obscureText` / `actions`
   - 下拉：`items` / `initialValue` / `icon` / `contentPadding`
   - 多选：`disabledKeys` / `itemStyle` / `itemCheckedStyle`
   - 日期：`firstDate` / `lastDate` / `displayFormat`
   - 按钮：`label` / `hintWidget` / `selectedWidgetBuilder`
6. 边框 / 校验 / 只读由 `WForm` 统一提供，不要在页面里堆
   `WFormTheme`、`WFormScope`、`WFormReadOnlyScope`。
7. `WForm` 与 `WFormController` 一对一使用。
8. 提交校验优先：

```dart
if (!form.validate()) return;
```

9. 只读与字段级样式：

```dart
WForm(controller: form, readOnly: true, child: ...);

WFormFieldStyleScope(
  style: const WFormFieldStyle(height: 72),
  child: WFormTextField(name: 'bio', maxLines: 3),
);
```

10. 其他字段与弹层：

```dart
WFormMultiDropdown(name: 'tags', items: const {'a': 'A'}, disabledKeys: const {'b'});
WFormDatePicker(name: 'birthday', label: '生日', displayFormat: 'yyyy-MM-dd');
WFormCheckbox(name: 'agree', title: Text('同意'), bordered: true);
WFormRadioGroup<String>(name: 'gender', items: const {'male': '男'}, bordered: true);
WFormButton(
  name: 'coupon',
  label: '请选择优惠券',
  onTap: (value, didChange) => didChange('new_user'),
);

final value = await WFormPopup.show<String>(
  context: context,
  anchorContext: fieldKey.currentContext,
  builder: (context) => ...,
);
```

11. 输入格式化 / 图标 / 统一校验：

```dart
WFormTextField(name: 'phone', inputFormatters: WFormInputFormatters.phone());
WForm(controller: form, icons: const WFormIcons(dropdown: Icon(Icons.expand_more)), child: ...);

form.validators(items: [WFormValidatorItem.field('email')]).validate();
form.validate(settings: WFormValidatorSettings()..continueOnError = true);
form.reset();
```

完整说明：[form_module.md](../modules/form_module.md)  
可运行示例：[packages/form/example](../../packages/form/example/README.md)
