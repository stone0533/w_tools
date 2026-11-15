> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# app_getx 3.1 迁移

`w_tools_app_getx 3.1.0` 没有 API 删除 / 签名变化，只把依赖下界收紧到
`w_tools_app ^4.0.0`。

## 依赖

```yaml
dependencies:
  w_tools_app_getx: ^3.1.0
  w_tools_app: ^4.0.0
```

- 3.1.0 不再声明兼容 `app 3.2.0`；页面作用域（`WApp.of` / `WLanguageScope`）与行为
  按 app 4.0.0 设计。
- 仍锁在 `app 3.2.0` 的项目请继续用 `app_getx 3.0.0`，或先把 `app` 升到 4.0.0。
- 3.0.0 引入的 `WAppScope` / `WApp.of` / `WLanguageScope` 用法不变。
