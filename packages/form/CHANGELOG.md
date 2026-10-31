# Changelog

## 2.0.0

### Changed
- 新增 `WFormFieldChrome`，六个字段 Config 与 `WFormFieldButtonConfig` 统一继承公共外框配置。
- 新增 `WFormController.updateValue`，同时写值并更新输入状态。
- 新增 `WFormController.validate()`；`isAllEntered` 改为显式字段名集合。
- 新增 `WFormBorderConfig.standard()`，并提供 `WFormTheme.borderConfig` 作用域继承。
- `WFormTextFieldConfig.enabled=false` 现在进入只读态，不再静默失效。
- 修复 `WFormMultiDropdownConfig.hintText` 不生效。

### Breaking
- `WFormData` → `WFormController`；
- `WFormButton` / `WFormButtonConfig` → `WFormFieldButton` / `WFormFieldButtonConfig`；
- `WFormBorderWithData` → `WFormFieldShell`；
- `WFormBuilder` → `WFormScope`；
- `WFormController.didChange` → `setValue`；`onChange` → `handleChange`；
- `WInputFormatters` → `WFormInputFormatters`；
- 新增 `WFormTheme`：按页面 / 品牌隔离表单图标，`WFormDefaults` 保留为静态兜底。

### Changed
- 拆分 `text_field_actions.dart`，文本框 action 独立维护；
- 拆分 `multi_dropdown` 的 field / item / config part 文件；
- 新增 `WFormDefaults.reset()`；`WFormFieldShell` 卸载时同时清理 `formEntered`。

### Fixed
- `WFormFieldShell` 卸载时注销 `formBorderKeys`，避免动态字段累积 GlobalKey。

## 1.0.1

### Fixed
- Flutter 3.38 起 `SizeTransition.alignment` 已移除，`WFormPopupRoute` 改用
  `axisAlignment: -1.0`（等价于原来的顶部对齐）。修复 1.0.0 在 Flutter 3.38+ 编译失败。

## 1.0.0

首次发布。

- 字段 Config 统一为 `build({bool bordered = false, ...})`：`buildBordered(...)` 合并为
  `build(bordered: true, ...)`，`key` 参数更名为 `borderKey`
  （影响 `WFormTextFieldConfig` / `WFormDropdownConfig` / `WFormMultiDropdownConfig` /
  `WFormCheckboxConfig` / `WFormRadioGroupConfig` / `WFormDatePickerConfig` / `WFormButtonConfig`）。
- 内部：7 个字段重复的 `Container + Row` 外框与 bordered 装配抽到内部 `WFormFieldFrame`
  （不对外导出），行为不变。
- 新增字段组件：`WFormTextField` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup`
- 新增表单容器：`WFormBuilder` / `WFormData` / `WFormButton`
- 新增边框体系：`WFormBorder` / `WFormBorderConfig` / `WFormBorderWithData` / `WFormReadOnlyScope`
- 新增校验能力：`WFormValidator` / `WFormValidatorItem` / `WFormCustomValidator`
- 新增默认值与输入格式化工具：`WFormDefaults` / `WInputFormatters`
- 支持字段级 `validator` 透传与配置化构建