# w_tools 聚合包示例

最小聚合入口示例，只依赖：

```yaml
w_tools:
  path: ../
```

页面只 import：

```dart
import 'package:w_tools/w_tools.dart';
```

覆盖：

- `WForm` + 直接字段
- `WFormTextField`
- `WFormDropdown`
- `WButton`
- `WFormController.validate`
- `WAsyncController` + `WAsyncView`

## 运行

```bash
cd example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 说明

聚合包只带上 6 个基础子包（core / async / ui / form / api / toast）；
app / app_getx / map / map_google / qr 不聚合，按需直接依赖对应子包。

生产项目建议按需依赖子包；本示例只用于验证聚合入口的实际用法。

异步区块只演示 `loading → ready`；失败 / 重试 / 分页等完整异步能力见：

```text
packages/async/example/
```
