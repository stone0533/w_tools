- **Forms** (`explain WForm`): `WForm` + direct fields `WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`; `WFormController`
  must be one-to-one; whole-form read-only via `readOnly`; validation with `WFormValidator` /
  `WFormValidatorSettings`; `WFormButton` for field values; never start from `Config.build`.
