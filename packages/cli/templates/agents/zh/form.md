- **表单**：新页面用 `WForm` + 直接字段（`WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`），
  不要从 `Config.build` 开始。
  `WForm` 需要 `WFormController`，且必须一对一（同一个 controller 同时挂载两个
  `WForm` 会显示重复挂载提示）；页面级高度 / 内边距用 `WForm.fieldStyle`
  （`WFormFieldStyle`），校验设置用 `WFormValidatorSettings` / `WFormValidator`；
  整表变化用 `WForm(onChanged:)`；字段差异用直接参数，不要传字段 `config`。
- **只读**：整页只读用 `WForm(readOnly: true)`；单字段只读用字段的 `readOnly`，
  不要手写只读作用域。
- **表单字段按钮**：字段值选择用 `WFormButton`，不要用 `WButton` 承担表单字段值。
- **表单弹层**：锚定选择用 `WFormPopup`，它不是居中确认框。
- **边框**：默认跟随主题，不需要显式传 `borderStyle`；固定浅色页才用 `WFormBorderStyle.standard()`；不要手写 `WFormBorder`。
- **输入格式化 / 插槽动作**：`WFormInputFormatters.hkPhone()`；文本插槽用
  `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton`。
