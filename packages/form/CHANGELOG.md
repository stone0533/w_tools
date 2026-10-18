# Changelog

## Unreleased

- **行为变更（breaking）**：字段 Config 的 `build()` / `buildBordered()` 双入口合并为单一 `build({bool bordered = false, ...})`。
  - `bordered: false`（默认）返回裸字段；`bordered: true` 返回包装了 `WFormBorderWithData` 的版本（清空内层 `containerDecoration`）。
  - 原 `buildBordered` 的 `key` 参数更名为 `borderKey`。
  - 影响：`WFormTextFieldConfig` / `WFormDropdownConfig` / `WFormMultiDropdownConfig` / `WFormCheckboxConfig` / `WFormRadioGroupConfig` / `WFormDatePickerConfig` / `WFormButtonConfig`；旧 `buildBordered(...)` 调用点需改为 `build(bordered: true, ...)`。
- 内部：7 个字段重复的 `Container + Row` 外框与 bordered 装配抽到内部 `WFormFieldFrame`（不对外导出），行为不变。

## 1.0.0

首次发布。

- 新增字段组件：`WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`
- 新增表单容器：`WFormBuilder` / `WFormData` / `WFormButton`
- 新增边框体系：`WFormBorder` / `WFormBorderConfig` / `WFormBorderWithData` / `WFormReadOnlyScope`
- 新增校验能力：`WFormValidator` / `WFormValidatorItem` / `WFormCustomValidator`
- 新增默认值与输入格式化工具：`WFormDefaults` / `WInputFormatters`
- 支持字段级 `validator` 透传与配置化构建
