# w_tools_form 示例

真实场景示例，覆盖：

- 登录表单：`WForm` 容器、直接字段构造、字段 validator、`WFormValidatorSettings`
- 会员资料：下拉、日期、单选、多选、复选、自定义 `WFormButton`
- 只读预览：`WForm(readOnly: true)`
- 统一边框 / 图标：`WFormBorderConfig` + `WForm`

## 运行

```bash
cd packages/form/example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 目录

```text
lib/
  main.dart             示例入口 + 底部导航
  form_style.dart       共享边框 / 高级样式覆盖
  pages/
    login_page.dart     登录场景
    profile_page.dart   资料编辑 / 只读场景
test/
  example_smoke_test.dart
```

## 使用方式

### WForm 统一容器

```dart
WForm(
  controller: form,
  borderConfig: exampleBorderConfig,
  fieldStyle: const WFormFieldStyle(
    height: 52,
    containerPadding: EdgeInsets.symmetric(horizontal: 16),
  ),
  readOnly: isReadOnly,
  child: ListView(...),
)
```

自动组合：

```text
WFormTheme
WFormScope
WFormReadOnlyScope
```

### 直接字段构造

```dart
WFormTextField(
  name: 'email',
  label: '邮箱',
  message: '请输入邮箱',
  validator: (value) {
    if (value == null || value.isEmpty) return '请输入邮箱';
    return null;
  },
)
```

### 高级样式覆盖

```dart
WFormTextField(
  name: 'email',
  label: '邮箱',
  config: exampleTextConfig(),
)
```

字段 Config 可变，**一个字段一份 Config**，不要跨字段共享同一实例。

样式优先级：

```text
字段 config > WForm.fieldStyle > 默认值
```

### 自定义字段按钮

```dart
WFormButton(
  name: 'coupon',
  label: '请选择优惠券',
  onTap: (_, didChange) async {
    final value = await pickCoupon();
    if (value != null) didChange(value);
  },
)
```

### 校验与提交

```dart
final valid = form.validate(
  settings: WFormValidatorSettings()
    ..showBorderError = true
    ..continueOnError = true,
);
if (!valid) return;
```
