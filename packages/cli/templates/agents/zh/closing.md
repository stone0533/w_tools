## 硬规则

- pubspec 只依赖具体子包，禁止聚合包 `w_tools`。
- 业务代码只 import 聚合入口，禁止直接 import `package:w_tools_*`。

## 检查项

{{doctorRules}}

## 完成前

- `dart run w_tools_cli:doctor --json` → 0 error（warning 看情况）
- `flutter analyze`、`flutter test`
<!-- w_tools:end -->
