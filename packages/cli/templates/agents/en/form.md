- **Forms**: use `WForm` + direct fields (`WFormTextField`, etc.); do not start from
  `Config.build`. `WForm` requires a `WFormController` (one-to-one); use `WForm.fieldStyle`
  for page-level height/padding and `WFormValidatorSettings` for validation; use direct field
  parameters for field-specific differences, not field `config`.
- **Form-field buttons**: use `WFormButton` for field value selection; do not use `WButton` for form values.
- **Form overlays**: use `WFormPopup` for anchored selection; it is not a centered dialog.
