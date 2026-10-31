# Form 使用规则

新页面默认使用 `WForm` + 直接字段，不要从 `Config.build` 开始写。

```dart
WForm(
  controller: form,
  borderConfig: WFormBorderConfig.standard(radius: 12),
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

1. 页面容器用 `WForm`。
2. 字段直接用 `WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup` / `WFormButton`。
3. 普通页面不要写 `WFormTheme`、`WFormScope`、`WFormReadOnlyScope` 三层嵌套。
4. 普通页面不要用 `WFormTextFieldConfig().build(...)`；需要特殊样式时传 `config`。

```dart
// 不推荐作为页面入口
(WFormTextFieldConfig()..height = 52).build(name: 'email')

// 推荐
WFormTextField(name: 'email', label: '邮箱')
```

5. 样式优先级：字段 `config` > `WForm.fieldStyle` > 默认值。
6. 字段 Config 可变，一个字段一份，不要跨字段共享。
7. `WForm` 与 `WFormController` 一对一使用。
8. `WFormTextFieldCore` 等 `*Core` 只用于底层封装或特殊布局。
9. 提交校验优先：

```dart
if (!form.validate()) return;
```

完整说明：[form_module.md](../modules/form_module.md)  
可运行示例：[packages/form/example](../../packages/form/example/README.md)
