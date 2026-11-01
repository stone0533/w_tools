# w_tools 聚合包示例

最小聚合入口示例，只依赖：

```yaml
w_tools:
  path: ../
```

页面只 import：

```dart
import 'package:w_tools/w.dart';
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

聚合包会带上 9 个 Flutter 子包及其依赖（包括 map / qr / GetX）。

生产项目建议按需依赖子包；本示例只用于验证聚合入口的实际用法。
