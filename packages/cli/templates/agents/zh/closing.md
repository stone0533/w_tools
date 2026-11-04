## 硬规则

- pubspec 只依赖具体子包，禁止聚合包 `w_tools`。
- 业务代码只 import 聚合入口，禁止直接 import `package:w_tools_*`。

## 检查项

> R6 需在 `.w_tools_doctor.yaml` 开启；R9 需配置 `banned`。
> 实际启用状态以项目配置为准。

{{doctorRules}}

## 完成前

- `dart run w_tools_cli:doctor --json` → 0 error（warning 看情况）
- `flutter analyze`、`flutter test`
- 本次用过 `w_tools_*` 且被卡住？→ 先 `feedback search` 查重，再 `feedback submit`（见「使用反馈（给 AI）」）；
  不要改库、不要直接写台账。
<!-- w_tools:end -->
