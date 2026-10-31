# w_tools_form 示例

真实场景示例，覆盖：

- 登录表单：文本 / 密码、字段 validator、`WFormValidatorSettings`、提交
- 会员资料：下拉、日期、单选、多选、复选、自定义字段按钮
- 只读预览：`WFormReadOnlyScope`
- 统一边框 / 图标：`WFormTheme` + `WFormBorderConfig`

## 运行

```bash
cd packages/form/example
flutter pub get
flutter run
```

如果没有连接设备，可以先运行静态分析和测试：

```bash
flutter analyze
flutter test
```

## 目录

```text
lib/
  main.dart             示例入口 + 底部导航
  form_style.dart       共享边框 / 字段 Config 工厂
  pages/
    login_page.dart     登录场景
    profile_page.dart   资料编辑 / 只读场景
test/
  example_smoke_test.dart
```

## 关键约定

### 一个字段一份 Config

字段 Config 是可变的。每个字段都调用一次工厂函数：

```dart
final emailConfig = exampleTextConfig();
final passwordConfig = exampleTextConfig();
```

不要：

```dart
final shared = exampleTextConfig();

WFormTextField(config: shared, name: 'email');
WFormTextField(config: shared, name: 'password');
```

### Config + build 需要括号

```dart
(WFormTextFieldConfig()
      ..height = 52)
    .build(
      name: 'email',
      bordered: true,
    );
```

因为 cascade 返回的是 Config，不是 `build()` 返回的 Widget。

### 共享样式用主题

```dart
WFormTheme(
  borderConfig: exampleBorderConfig,
  child: ...,
)
```

`exampleBorderConfig` 是不可变配置，可以安全共享。
