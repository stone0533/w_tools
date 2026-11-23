- **Forms** (`explain WForm`): `WForm` + direct fields `WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`; `WFormController`
  must be 1:1; whole-form read-only via `readOnly`; validation with `WFormValidator` /
  `WFormValidatorSettings`; `WFormButton` / `WFormFieldStyleScope` for field values; never start from `Config.build`.
