- **Forms**: use `WForm` + direct fields (`WFormTextField` / `WFormDropdown` /
  `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`);
  do not start from `Config.build`.
  `WForm` requires a `WFormController` (one-to-one); page-level height/padding use
  `WForm.fieldStyle` (`WFormFieldStyle`); validation uses `WFormValidatorSettings` /
  `WFormValidator`; field differences use direct parameters, never a field `config`.
- **Read-only**: use `WForm(readOnly: true)` for a whole form; use the field's
  `readOnly` for a single field; do not hand-write the read-only scope.
- **Field buttons**: use `WFormButton` for field value selection; do not use `WButton`
  to hold a form field value.
- **Form popups**: use `WFormPopup` for anchored selection; it is not a centered dialog.
- **Borders**: default to `WFormBorderConfig.fromTheme(Theme.of(context))`; do not
  hand-write `WFormBorder`.
- **Input formatters / slot actions**: `WFormInputFormatters.phone()`; text slots use
  `WFormTextFieldPasswordToggle` / `WFormTextFieldClearButton`.
