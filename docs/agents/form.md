# Form 使用规则

新页面默认使用 `WForm` + 直接字段（`WFormTextField` / `WFormDropdown` 等），
不要从 `Config.build` 开始写。

```dart
WForm(
  controller: form,
  // 边框默认跟随主题；只有固定浅色页才显式用 WFormBorderStyle.standard()
  fieldStyle: const WFormFieldStyle(height: 52),
  child: Column(
    children: [
      WFormTextField(
        name: 'email',
        hintText: '邮箱',
        message: '请输入邮箱',
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入邮箱';
          return null;
        },
      ),
      WFormDropdown<String>(
        name: 'country',
        hintText: '国家 / 地区',
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
   - 文本：`hintText` / `message` / `validator` / `obscureText` / `actions`（`label` 已弃用，用 `hintText`）
   - 下拉：`items` / `initialValue` / `icon` / `contentPadding`
   - 多选：`disabledKeys` / `itemStyle` / `itemCheckedStyle`
   - 复选 / 单选：`message`（有边框时交给 hint / error builder；无边框时渲染在字段下方）/ `title` / `items`
   - 日期：`firstDate` / `lastDate` / `displayFormat`
   - 按钮：`label` / `message` / `hintWidget` / `selectedWidgetBuilder`（`WFormButton` 是
     `WFormFieldButton<String>` 的 typedef，两者是同一类型；enum / int 用 `WFormFieldButton<T>`）
6. 边框 / 校验 / 只读由 `WForm` 统一提供，不要在页面里堆
   `WFormTheme`；`WFormScope` / `WFormReadOnlyScope` 8.0 起移除公开入口；整表变化用
   `WForm(onChanged:)`，不要逐字段拼回调。
7. `WForm` 与 `WFormController` 必须一对一：同一个 controller 同时挂载两个
   `WForm` 时，第二个不会构建 `FormBuilder`，而是显示重复挂载提示。
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

`WFormFieldStyle.height` 只对单行字段生效；单选组、多行文本由内容撑高。

10. 其他字段与弹层：

```dart
WFormMultiDropdown(name: 'tags', items: const {'a': 'A'}, disabledKeys: const {'b'});
WFormDatePicker(name: 'birthday', hintText: '生日', displayFormat: 'yyyy-MM-dd');
WFormCheckbox(name: 'agree', title: Text('同意'));
WFormRadioGroup<String>(name: 'gender', items: const {'male': '男'});
WFormButton(
  name: 'coupon',
  label: '请选择优惠券',
  onTap: (value, didChange) => didChange('new_user'),
);
```

需要锚定弹层时用 Flutter 的 `MenuAnchor` / `showMenu`；`WFormPopup` 8.0 起移除公开入口。

11. 图标 / 统一校验：

```dart
WForm(controller: form, icons: const WFormIcons(dropdown: Icon(Icons.expand_more)), child: ...);

form.validators(items: [WFormValidatorItem.field('email')]).validate();
form.validate(settings: const WFormValidatorSettings(continueOnError: true));
form.reset();
```

完整说明：[form_module.md](../modules/form_module.md)  
可运行示例：[packages/form/example](../../packages/form/example/README.md)
