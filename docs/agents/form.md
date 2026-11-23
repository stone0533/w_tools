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
   - 多选：`disabledKeys` / `itemStyle` / `itemCheckedStyle` / `itemPadding`（默认行高 48）
   - 复选 / 单选：`message`（有边框时交给 hint / error builder；无边框时渲染在字段下方）/ `title` / `items`
   - 日期：`firstDate` / `lastDate` / `displayFormat` / `clearable`
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
// 只读：文本可聚焦 / 复制；非文本字段为不可交互的只读态；真正禁用用 enabled: false
WForm(controller: form, readOnly: true, child: ...);

// 只改高度、其余沿用页面样式
WFormFieldStyleScope(
  style: const WFormFieldStyle(height: 72),
  mergeWithParent: true,
  child: WFormTextField(name: 'bio', maxLines: 3),
);
```

`WFormFieldStyleScope` 默认**整体替换**页面样式（只传 height 会丢 padding / 文字 / 占位样式）；
只改部分字段用 `mergeWithParent: true`（null = 沿用外层），要清空 / 完全接管才用默认替换；
`pageStyle.copyWith(...)` 适合显式派生完整样式；
`WFormFieldStyle.height` 对文本 / 下拉是最小高度（错误文案 / 计数器 / 多行会撑高），
单选组等由内容决定高度。

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

自定义校验直接传 `validator:` 闭包（`value` 可能为 `null`，必填自己判）；表单级用
`WFormValidatorItem.field(name)` 复用字段规则，或用 `validatorBuilder` 生成动态规则。
`WFormCustomValidator` 已在 8.0 删除（只是函数包装），不要再去引用。
form.validate(settings: const WFormValidatorSettings(continueOnError: true));
form.reset();

// 回填：initialValue 只在首次挂载生效；异步数据用 setValue（需已挂载，挂载前会断言）
form.setValue('email', loaded.email);
```

完整说明：[form_module.md](../modules/form_module.md)  
可运行示例：[packages/form/example](../../packages/form/example/README.md)
