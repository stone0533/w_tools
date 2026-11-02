- **表单**：新页面用 `WForm` + 直接字段（`WFormTextField` 等），不要从 `Config.build` 开始。
  `WForm` 需要 `WFormController`，与 controller 一对一；页面级高度 / 内边距用
  `WForm.fieldStyle`，校验设置用 `WFormValidatorSettings`；字段特殊样式用字段 `config`。
- **表单字段按钮**：字段值选择用 `WFormButton`，不要用 `WButton` 承担表单字段值。
- **表单弹层**：锚定选择用 `WFormPopup`，它不是居中确认框。
