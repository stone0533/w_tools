# Flutter 项目测试策略（白盒 / 黑盒）

本文面向**使用 w_tools 的业务项目**，不是 w_tools 仓库自身的测试说明。

目标：

```text
先知道测什么
再知道用什么工具
最后知道怎么在 CI / 设备上跑
```

## 测试金字塔

推荐比例：

```text
60% 单元测试
30% widget 测试
10% 集成 / 黑盒
```

不要把所有验证都压到设备上的黑盒测试。

---

## 白盒测试

白盒测试可以访问项目内部：

```text
Controller
Repository
服务层
页面状态
```

适合：

- WForm 校验、提交、只读
- WAsyncController 四态
- API repository / 错误映射
- 列表分页状态
- 纯逻辑、格式化、校验器

### 最小 widget 测试

```dart
testWidgets('表单校验失败时不提交', (tester) async {
  final form = WFormController();
  var submitted = false;

  await tester.pumpWidget(
    MaterialApp(
      home: WForm(
        controller: form,
        child: Column(
          children: [
            WFormTextField(
              name: 'name',
              hintText: '名称',
              validator: (value) =>
                  (value == null || value.isEmpty) ? '请输入' : null,
            ),
            WButton(
              label: '提交',
              onTap: () => submitted = form.validate(),
            ),
          ],
        ),
      ),
    ),
  );

  await tester.tap(find.widgetWithText(WButton, '提交'));
  await tester.pump();

  expect(submitted, isFalse);
  expect(find.text('请输入'), findsWidgets);
});
```

### WAsync 四态

```dart
testWidgets('loading / empty / error / ready', (tester) async {
  final controller = WAsyncController<List<String>>(() async => []);

  await tester.pumpWidget(
    MaterialApp(
      home: WAsyncView<List<String>>(
        state: controller.state,
        onRetry: controller.load,
        readyBuilder: (context, data) => Text('${data.length}'),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsWidgets);

  await controller.load();
  await tester.pumpAndSettle();

  expect(find.text('空'), findsWidgets);
});
```

实际断言以 `WAsyncStrings` / 项目主题为准，不要依赖默认文案。

### 白盒测试规则

```text
不要启动真实网络
不要依赖真实 token
不要 sleep 等异步
Controller 要 dispose
测试失败要能定位到具体状态
```

---

## 黑盒测试

黑盒测试只通过用户可见入口操作：

```text
启动 App
登录
点击页面
输入
等待加载
截图 / 区域校验
```

工具：

```text
integration_test
flutter drive
w_tools_device
w_tools_e2e
```

### 选择器

优先级：

```text
Key
Semantics
稳定文本
坐标（最后手段）
```

页面至少给关键入口加稳定 Key：

```dart
WButton(
  key: const Key('login_submit'),
  label: '登录',
  onTap: _login,
)
```

不要在测试里依赖：

```text
随机文案
动画中间态
屏幕绝对坐标
```

### integration_test 最小结构

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('登录 → 首页 → 返回', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'password');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_root')), findsOneWidget);
  });
}
```

运行：

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

### 设备黑盒

`w_tools_device` 适合“启动 App 后点击 / 截图 / 等区域变化”：

```bash
dart run w_tools_device:device list
dart run w_tools_device:device boot "<名称>"
dart run w_tools_device:device shot --out=/tmp/home.png
dart run w_tools_device:device tap <x> <y>
dart run w_tools_device:device wait --region=<x,y,w,h>
dart run w_tools_device:device verify <x> <y> --region=<x,y,w,h>
```

这是**坐标级兜底**，优先使用 `integration_test` + Key。

### E2E 免登录

`w_tools_e2e` 只负责测试账号登录：

- 编译期开关 `E2E=1`
- 凭证不提交仓库
- 测试入口与生产入口分开

见 [E2E 免登录](../recipes/e2e-login.md)。

---

## 测试账号 / 测试数据

```text
测试账号只用于测试
不要复用真实密码
不要把 token / 密码写进仓库
测试数据要可重复创建 / 清理
```

黑盒测试如果依赖后端，先确认：

```text
测试环境稳定
测试账号可登录
数据可重置
失败时有截图 / 日志
```

---

## CI 建议

最小：

```bash
flutter analyze
flutter test
```

加集成测试：

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

设备矩阵 / 真机：

```text
单独 job
允许 manual / nightly
失败保留截图
```

不要默认在所有 PR 上跑大量真机黑盒。

---

## 反模式

```text
只测 happy path
只做黑盒，不测 Controller
测试里 sleep
依赖坐标点击
用生产账号
为了通过改断言
```

---

## w_tools 能提供什么

```text
WForm / WAsync / WImage 的稳定入口
w_tools_device 的设备操作
w_tools_e2e 的测试登录入口
示例和 recipe
```

w_tools 不提供：

```text
业务断言
测试数据
页面路由
CI 账号
```

这些由项目自己负责。

---

## 相关

- [设备验证](../agents/device-testing.md)
- [Tab 设备冒烟示例](../../packages/device/example/README.md)
- [E2E 免登录](../recipes/e2e-login.md)
- [表单提交](../recipes/form-submit.md)
