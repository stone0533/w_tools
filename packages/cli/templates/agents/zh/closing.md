## 硬规则

- pubspec 只依赖具体子包，禁止聚合包 `w_tools`。
- 业务代码只 import 聚合入口，禁止直接 import `package:w_tools_*`。

## 检查项

> R6 需在 `.w_tools_doctor.yaml` 开启；R9 需配置 `banned`。
> 实际启用状态以项目配置为准。

{{doctorRules}}

## 完成前

- `dart run w_tools_cli:w_tools doctor --format=json` → 0 error（warning 看情况）
- `flutter analyze`、`flutter test`
- 本次用过 `w_tools_*` 且被卡住？→ 先看 `.w_tools_doctor.yaml` 的 `feedback.issue`；
  未开启就跳过（这是默认）；开启后按「使用反馈」search → submit。
<!-- w_tools:end -->
