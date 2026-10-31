# Changelog

## 2.0.0

### Changed
- 新增 `WForm` 容器、`WFormFieldStyle` 默认字段样式与 `validatorSettings` 默认校验设置；config 优先级高于 fieldStyle。
- 修复 `WFormDatePicker` 传 config 时 label hint 丢失、`WFormButton` 传 config 时 hintWidget 被清空。
- 移除字段 `borderKey` 参数；边框 key 统一由 `WFormFieldShell` 按 `name` 自动注册，避免重复 GlobalKey。
- 新增直接字段构造 API（`WFormTextField` / `WFormDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup` / `WFormButton` 等）。
- 原字段 Widget 重命名为 `*Core` 作为低层实现；普通页面不再需要 `Config.build`。
- 新增登录 / 会员资料可运行示例 `example/`。
- 字段 Config 统一为可变 cascade，继承 `WFormFieldBaseConfig`；`WFormBorderConfig` 保持不可变。
- 移除字段 Config Builder；边框保留 `WFormBorderConfigBuilder`。
- `WFormValidatorConfig` 重命名为 `WFormValidatorSettings`，`validators` / `validate` 参数统一为 `settings`。
- 新增 `WFormController.updateValue`，同时写值并更新输入状态。
- 新增 `WFormController.validate()`；`isAllEntered` 改为显式字段名集合（空集合返回 false）。
- 裸字段 `readOnly` 通过 `WFormReadOnlyScope` 生效；无状态下拉也通过 `WFormFieldCleanup` 清理 `formEntered`。
- `WFormBorder` 可直接读取 `WFormTheme.borderConfig`，不再要求主题必须先于 Scope；改为 `WFormBorderConfigScope`，消除 border / scope / theme 循环 import。
- 新增 `WFormBorderConfig.standard()`，并提供 `WFormTheme.borderConfig` 作用域继承。
- `WFormTextFieldConfig.enabled=false` 现在真正禁用文本字段，不再静默失效；新增 `clearValue`。
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