# w_tools_form 示例

真实场景示例，覆盖：

- 登录表单：`WForm` 容器、直接字段构造、字段 validator、`WFormValidatorSettings`
- 会员资料：输入格式化、下拉、日期配置、单选、多选、复选、自定义 `WFormButton`
- 只读预览：`WForm(readOnly: true)`
- 锚定弹层：`WFormPopup` + `WFormButton`
- 高级字段：leading / maxLines / 禁用下拉 / 自定义勾选 / 单选样式 / controller 读取
- 自定义边框：`WFormBorderConfig` 的聚焦 / 错误装饰、hint / error builder、itemValidationCallback
- 统一边框 / 图标：`WFormBorderConfig` + `WForm` 的 icon 配置

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
    popup_page.dart     WFormPopup 锚定弹层
    advanced_fields_page.dart 字段 Config / controller 读取
    border_page.dart   自定义 WFormBorderConfig
test/
  example_smoke_test.dart
```

## 使用方式

### WForm 统一容器

```dart
WForm(
  controller: form,
  borderConfig: exampleBorderConfig,
  fieldStyle: exampleFieldStyle,
  validatorSettings: WFormValidatorSettings()
    ..showBorderError = true
    ..continueOnError = true,
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
// WForm 上统一设置一次
WForm(
  validatorSettings: WFormValidatorSettings()
    ..showBorderError = true
    ..continueOnError = true,
  ...
)

// 页面提交时直接使用默认设置
if (!form.validate()) return;
```

### 锚定弹层

```dart
final anchor = anchorKey.currentContext!;
final value = await WFormPopup.show<String>(
  context: anchor,
  anchorContext: anchor,
  width: 220,
  builder: (popupContext) => ...,
);
```
