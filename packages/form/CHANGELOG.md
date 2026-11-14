## 8.0.0

### Breaking
- 删除 `WFormController.clearValue`：清空用 `resetValue`，或对可空字段显式
  `setValue<String?>(name, null)`。
- 删除 `WFormController.formEntered` / `WFormController.isAllEntered`：判断是否填写直接读
  `value`，或用字段 validator 表达 required。
- 删除 `WFormController.closeKeyboard`：用 `FocusManager.instance.primaryFocus?.unfocus()`。
- 删除 `WFormCustomValidator`，并移除 `form_builder_validators` 依赖：自定义规则直接传
  `FormFieldValidator`（如 `validator: (value) => ...`）。
- 删除 `WFormInputFormatters` / `WCardNumberInputFormatter` / `WDividerInputFormatter`：
  输入格式化直接用 `flutter/services.dart` 的 `FilteringTextInputFormatter` /
  `LengthLimitingTextInputFormatter`，或 `TextInputFormatter.withFunction`。
- `WFormCheckbox.new` / `WFormRadioGroup.new` 的 `bordered` 默认值由 `false` 改为 `true`；
  需要旧视觉请显式传 `bordered: false`。
- `WFormFieldShell.new` 新增 `rendersInlineError` 可选参数（默认 `true`）；
  不渲染 `errorText` 的自定义字段传 `false`，由边框兜底展示原生错误。
- `WFormScope` / `WFormReadOnlyScope` / `WFormTextFieldScope` 不再公开：
  `WFormScope.of` / `WFormScope.requireOf` → `WFormController.of` / `WFormController.requireOf`；
  `WFormScope.borderStyleOf` → `WFormThemeData.of(context)?.borderStyle`；
  `WFormReadOnlyScope.readOnlyOf` → `WFormReadOnly.of`；
  `WFormTextFieldScope.of` → `WFormTextFieldData.of`。
- `WFormBorder` / `WFormBorderLayout` / `WFormBorderLayoutData` / `columnBorderLayout` 不再公开：
  边框由 `WFormFieldShell` 内部装配；自定义字段继续用 `WFormFieldShell`。
- `WFormBorderStyle.new` / `WFormBorderStyle.copyWith` 删除 `layout` 参数。
- `WFormBorderStyle.layout` 删除：布局固定为「边框在上、消息在下」。
- 删除 `WFormDatePicker.initialDate`：初值只接受 `initialValue`（ISO `yyyy-MM-dd`）；
  `DateTime` 请先格式化。
- `WFormController.validatorSettings` 改为只读 getter（原先可写字段）：默认校验设置只由
  `WForm(validatorSettings:)` 注入；单次调用用 `validate(settings:)` / `validators(settings:)`。
- 移除 `WFormPopup` 公开入口（`WFormPopup.show` / `WFormPopup.hide`）；`WFormMultiDropdown` 的弹层
  仍由包内实现。需要锚定弹层时用 Flutter 的 `MenuAnchor` / `showMenu` / `OverlayPortal`。
- 迁移见 `docs/migrations/form-8.0.md`。

### Deprecated
- `WFormFieldStyle.hintStyle` → `placeholderStyle`；`WFormBorderStyle.hintStyle` → `helperStyle`；
  `remove-in: 9.0.0`。
- `WFormTextField.label` / `WFormDropdown.label` / `WFormMultiDropdown.label` /
  `WFormDatePicker.label`：占位符改用 `hintText`；`remove-in: 9.0.0`。
  `WFormFieldButton.label` / `WFormButton.label` 不受影响。

### Added
- `WFormFieldStyle.placeholderStyle` / `WFormBorderStyle.helperStyle`：替代同名歧义的 `hintStyle`。
- `WFormController.save()`：显式保存当前值（触发字段 `onSaved`，刷新 `savedValue`）。
- `WFormController.of` / `WFormController.requireOf`、`WFormReadOnly.of`、
  `WFormTextFieldData.of`：替代三个内部 scope 的读取入口。
- `WFormFieldShell.rendersInlineError`：声明字段是否自己渲染
  `FormFieldState.errorText`。默认 `true` 保持自定义字段现状；checkbox / radio / date / multi /
  button 由直接字段传 `false`，交给边框展示原生 `validate()` 的错误。
- checkbox / radio / date / multi / button 的 `focusNode` 现在接到真正可交互的控件，
  `formKey.currentState.fields[name].focus()` 与 Tab 能落到控件上；支持 Enter / Space 激活
  （radio 的外部 `focusNode` 绑到第一个选项，其余选项保留各自焦点节点）。

### Changed
- `WFormValidator.validate()` / `WFormController.validate()` 不再隐式调用 `save()`：
  校验读取 `instantValue`，`savedValue` 与 `onSaved` 只在 `form.save()` 时更新。
- `WForm.fieldStyle.height` 不再套到 `WFormRadioGroup`：单选组高度由选项内容决定，
  避免 3 个及以上选项被固定高度裁掉。

### Fixed
- `WFormController.getFieldsValue` 字段名拼错时在 debug 断言，不再静默返回 null。
- `formKey.validate()` / `WForm.autovalidateMode` 写入 checkbox / radio / date / multi / button
  的 `errorText` 时，边框不再误判“文案已内联渲染”而吞掉自己的错误文案。
- 默认无边框的 checkbox / radio 校验失败时看不到错误：默认带边框后，validator 错误可在界面显示。
- `WFormController.setValue` / `resetValue` 字段名拼错时在 debug 断言报出，不再静默 no-op。

## 7.0.1

### Fixed
- `WFormController.setValue` 在字段自己的 `onChanged` 里回写同值时不再递归爆栈：
  同值回写直接 no-op。迁移 / README / catalog 明确该写法仍不推荐，`setValue` 只用于程序化改值。

## 7.0.0

### Breaking
- `WFormController.borders` 不再公开：边框错误通道由包内 `WFormBorderRegistry` 维护，业务侧继续用 `setError` / `clearError`。
- `WFormInputFormatters.new` 不再存在：该类是纯静态工厂，不能实例化；直接用 `WFormInputFormatters.hkPhone()`。
- `WFormInputFormatters.phone` 删除：用 `WFormInputFormatters.hkPhone()`（`remove-in: 7.0.0` 到期）。
- `WFormValidatorSettings.copy` 删除：用 `copyWith()` 生成新实例。
- `WFormBorderDecoration` / `WFormBorderDecorationExtension` 删除：装饰直接使用 Flutter `BoxDecoration`。
- `WFormBorderStyle.new` / `WFormBorderStyle.copyWith` / `WFormBorderStyle.defaultDecoration` / `WFormBorderStyle.readOnlyDecoration` / `WFormBorderStyle.errorDecoration` / `WFormBorderStyle.focusedDecoration` 的装饰类型改为 `BoxDecoration?`。
- 直接使用 `WFormBorder` 时必须显式传 `style`：它不再读取 `WFormTheme` / `WFormScope`；普通字段仍由 `WFormFieldShell` 自动接线。
- `WFormScope.formBorderStyle` / `WFormScope.new` 删除该参数：边框配置改用 `WFormTheme(borderStyle:)` / `WForm(borderStyle:)`。
- `WFormMultiDropdown.disabledKeys` / `WFormMultiDropdown.initialValue` / `WFormMultiDropdown.items` / `WFormMultiDropdown.new` / `WFormMultiDropdown.onChanged` / `WFormMultiDropdown.validator` 随 `WFormMultiDropdown<T>` 泛型化改为 `T` / `Set<T>`；String 用法可由 items 推断，显式类型标注需要补 `<String>`。
- `WFormController.updateValue` / `WFormController.handleChange` 删除：`WFormController.setValue` 现在同时清除该字段边框错误；只清错误用 `WFormController.clearError`。
- 迁移见 `docs/migrations/form-7.0.md`。

### Added
- `WFormTextField.textAlign` / `maxLength`：直接文本字段补齐常用输入参数。
- `WFormDropdown.style` / `iconSize`：单字段覆盖选项文字样式与右侧图标尺寸。
- `WFormDatePicker.initialDate`：用 `DateTime` 给初值，自动转 ISO；与 `initialValue` 二选一。
- `WFormTextFieldAction.semanticLabel` / `semanticLabelBuilder`、`WFormTextFieldPasswordToggle.showSemanticLabel` / `hideSemanticLabel`、`WFormTextFieldClearButton.semanticLabel`：为文本插槽按钮提供读屏标签；清空按钮未传时回退到本地化 `clearButtonTooltip`。

### Fixed
- `WFormValidator` 先写边框错误、下一帧再走原生 `formKey.validate()` 时，同一字段的错误文案不再渲染两次。
- `WFormValidatorSettings.shouldSkipValidation` 跳过的字段不再保留上一次的边框错误（条件隐藏 / 停用字段不会残留红框）。
- 表单未挂载时，字段校验项 / 空校验项的 `WFormValidator.validate()` 返回 `false`，与 `WFormController.validate()` 一致；纯自定义 `validatorBuilder` 仍可运行。
- 文本 `actions` 与多选弹层选项补齐 `button` + `onTap` 语义，并支持 Enter / Space 键盘激活。
- 修正 `WFormFieldShell`、`WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup` 的类文档，以及 6.0 后过期的边框 key / 类型独立表述。

### Changed
- `WFormTheme` / `WFormThemeData` 成为边框样式唯一来源；内部 `WFormBorderStyleScope` 删除。

## 6.0.0

### Breaking
- `WForm` / `WFormTheme` 移除 8 个单项图标参数（`dropdownIcon`、`radioUnselectedIcon`、
  `radioSelectedIcon`、`checkboxUnselectedIcon`、`checkboxSelectedIcon`、
  `obscureTextIcon`、`obscureTextVisibleIcon`、`clearButtonIcon`）：
  统一用 `icons: WFormIcons(...)`；`WForm` 仍会继承外层 `WFormTheme.icons`。
- `WFormBorderConfig` 改名为 `WFormBorderStyle`（视觉样式，不是 Config）。同时改名：
  `WForm(borderConfig:)` → `borderStyle:`、`WFormTheme(borderConfig:)` → `borderStyle:`、
  `WFormScope.formBorderConfig` → `formBorderStyle`、`WFormScope.borderConfigOf` →
  `borderStyleOf`、`WFormBorder.config` → `WFormBorder.style`。
  删除零调用的 `WFormBorderConfig.build()` 与 `WFormBorderConfig.copy()`（用 `copyWith`）。
- 公开 barrel 不再导出 `WFormBorderStyleScope`、`WFormBorderState`、`WFormPopupRoute`
  （内部实现；`WFormPopup.show` / `hide` 不变）。
  移除的成员：`WForm.dropdownIcon`、`WForm.radioUnselectedIcon`、`WForm.radioSelectedIcon`、`WForm.checkboxUnselectedIcon`、`WForm.checkboxSelectedIcon`、`WForm.obscureTextIcon`、`WForm.obscureTextVisibleIcon`、`WForm.clearButtonIcon`、`WFormTheme.dropdownIcon`、`WFormTheme.radioUnselectedIcon`、`WFormTheme.radioSelectedIcon`、`WFormTheme.checkboxUnselectedIcon`、`WFormTheme.checkboxSelectedIcon`、`WFormTheme.obscureTextIcon`、`WFormTheme.obscureTextVisibleIcon`、`WFormTheme.clearButtonIcon`。
- `WFormFieldShell.useIntrinsicHeight` 删除：`WFormFieldShell.new` 不再接受该参数
  （没有任何调用方；需要时用外层 `IntrinsicHeight`）。
- `WFormController.formBorderKeys` / `ensureBorderKey` / `removeBorderKey` 不再公开：边框登记与
  错误通道由包内 `WFormBorderRegistry`（`border/border_registry.dart`，不导出）维护。
- 同版删除 `WFormController.errorChannelOf` / `removeErrorChannel` / `registerBorder` /
  `unregisterBorder` / `hasBorder`：业务侧只用 `setError` / `clearError`。
- 同版删除兼容 no-op `WFormController.pruneFormEntered` / `WFormController.removeFormEntered`
  （`formEntered` 已由字段值实时派生，没有需要手工清理的输入状态）。
- `WFormController.formEntered` 改为**按字段值实时派生的快照**：`setValue` / `updateValue`
  都会立即反映；返回的是独立副本，改它不影响表单。
- `WFormValidatorItem` 的 `fieldName` / `validatorBuilder` / `autofocus` 改为构造后不可变。
- `WFormValidator` 的 `formData` / `validationItems` / `settings` 改为 `final`（构造后不可换绑；
  `validationItems` 列表内容仍可 `add`）。
- `WFormButton` 改为 `typedef WFormButton = WFormFieldButton<String>`（不再是独立类）：
  `WFormButton.actions` / `WFormButton.bordered` / `WFormButton.build` / `WFormButton.enableFocusBorder` / `WFormButton.enabled` / `WFormButton.focusNode` / `WFormButton.hintTextList` / `WFormButton.hintWidget` / `WFormButton.initialValue` / `WFormButton.isTransparentBackground` / `WFormButton.label` / `WFormButton.leading` / `WFormButton.name` / `WFormButton.onTap` / `WFormButton.readOnly` / `WFormButton.selectedWidgetBuilder` / `WFormButton.validator`
  现在来自 `WFormFieldButton`，签名不变；
  `find.byType(WFormButton)` 等价于 `find.byType(WFormFieldButton<String>)`。

- 边框布局收敛为一个函数 `typedef WFormBorderLayout`（`WFormBorderLayout.new` /
  `WFormBorderLayout.column` / `WFormBorderLayout.builder` 不再存在）：删除 `WFormBorderColumnLayout` /
  `WFormBorderBuilderLayout` / `WFormBorderLayoutBuilder`，默认布局改为顶层
  `columnBorderLayout`；自定义布局直接传 `(context, data) => ...`。
- `WFormTheme` 拆成 widget + 数据：新增 `WFormThemeData`（icons / borderStyle + `effective*` + `of`），
  `effective*` getter 从 widget 移到数据类；`WFormTheme.maybeOf` 由返回 widget 改为返回数据。
  移除的成员：`WFormTheme.effectiveCheckboxSelectedIcon` / `WFormTheme.effectiveCheckboxUnselectedIcon` / `WFormTheme.effectiveClearButtonIcon` / `WFormTheme.effectiveDropdownIcon` / `WFormTheme.effectiveObscureTextIcon` / `WFormTheme.effectiveObscureTextVisibleIcon` / `WFormTheme.effectiveRadioSelectedIcon` / `WFormTheme.effectiveRadioUnselectedIcon` / `WFormTheme.maybeOf`
- `WFormValidatorSettings` 改为**不可变配置**：字段全部 `final`，新增 `const` 构造的命名参数；
  旧写法 `WFormValidatorSettings()..showBorderError = true` 不能再赋值，改用
  `const WFormValidatorSettings(showBorderError: true)`。`copy()` / `copyWith()` 仍返回新实例。
- 迁移见 `docs/migrations/form-6.0.md`。

### Added
- `WFormCheckbox` / `WFormRadioGroup` / `WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker`
  新增 `focusNode` 参数（与 `WFormTextField` / `WFormButton` 对齐），用于校验自动聚焦或外部接管焦点。
- `WFormController.resetValue(name)`：把单个字段重置回它自己的 `initialValue`（bool / Set 等非空值类型
  用它；`clearValue` 仍是一律写 `null`，只对可空类型语义明确，文档已注明）。
- `WFormTextField` / `WFormCheckbox` / `WFormDatePicker` 新增 `style` 参数：单字段覆盖正文样式，
  未传时仍取 `WForm.fieldStyle.textStyle`（与 `WFormRadioGroup.style` 对齐）。
- `WForm.onChanged`：任一字段变化后回调当前整表值（`Map<String, dynamic>`）。
- `WFormCheckbox.message` / `WFormRadioGroup.message`：与其余直接字段一致的提示文案入口
  （仅在 `bordered: true` 时渲染，与 `hintTextList` 二选一）。
- `WFormFieldButton<T>`：泛型字段选择器；`WFormButton` 保持原 String API，等价于 `WFormFieldButton<String>`。
- `WFormButton.message` / `WFormFieldButton.message`：提示文案简写（与 `hintTextList` 二选一）。

### Fixed
- `WFormDropdown` 忽略 `WForm.fieldStyle.containerPadding`：下拉内容现在与其余字段
  共用同一左内边距（同页不再错位）。
- `WForm` 只在 controller / `validatorSettings` 变化时重设默认校验设置：改 `borderStyle`
  不会再覆盖用户手动注入的 `controller.validatorSettings`。
- `WFormPopup` 水平方向钳制在安全区内：显式 `width` 大于锚点宽度、或锚点贴边时，
  弹层不再画到屏幕外。
- `bordered: false` 的字段同样校验空 `name`（与 `bordered: true` 一致抛 `ArgumentError`）。
- 外层 `WFormTheme` 的 `icons` 现在会被 `WForm` 继承，App 级统一图标生效。
- `WFormPopup.hide` 在没有弹层时不再 pop 普通页面（改为 no-op）。
- `WForm.fieldStyle` 的 `textStyle` / `hintStyle` 补齐到复选框标题、日期与多选占位符。
- 复选框 / 单选项补齐可点击语义与键盘激活（`Semantics.onTap` + `FocusableActionDetector`）。
- `WFormBorderState` 的 error / message 状态改为只读 getter，外部不能直接改。
- 同一个 `WFormController` 被两个 `WForm` 同时挂载时，第二个显示可读的重复挂载提示，
  不再只报底层 `GlobalKey` 冲突；owner 卸载后提示会自动恢复为表单。
- `bordered: false` 字段参与 `validate()` 时不再触发 debug 断言，错误只汇集到
  `WFormValidator.errors`（无边框字段没有可渲染的错误位置）。
- `WForm` 运行期换绑 controller 时会清理旧 controller 的默认校验设置。
- 已打开的多选弹层会跟随外部 `setValue` / `reset` 更新勾选态。

### Changed
- `WFormController.validators()` 不传 `items` 时校验当前已挂载字段，与 `validate()` 一致。
- `message` 与 `hintTextList` 同时传会在 debug 断言，不再静默丢弃 `message`。
- `bordered: false` 字段调用 `setError` 会在 debug 断言提示（release 仍 no-op），
  错误请从 `WFormValidator.errors` 读。
- `WFormTextFieldData` 从 `abstract final class` 改为 `abstract interface class`：消费方（或测试）
  可以自行 `implements` 它来 fake 输入框状态。
- `WFormDatePicker` 的默认 `lastDate` 从「今天」放宽到 `DateTime(2100)`：预约 / 到期日这类
  场景不再默认选不了未来；只要选过去的表单请显式传 `lastDate: DateTime.now()`。
- `WFormValidatorSettings` 增加 `==` / `hashCode`：按官方示例在 `build` 里内联构造等值设置时，
  不再每次重建都重写 `controller.validatorSettings`。
- `bordered: false` 的字段不再静默丢弃 `message` / `hintTextList`：改为渲染在字段下方
  （12px 默认文字样式，release 同样生效）；原来只有 debug 断言。
- 边框样式只保留**一个** `WFormBorderStyleScope` 通道：`WFormScope.borderStyleOf` 直接读该作用域，
  `WFormTheme` 在没有有效样式时不再插入空作用域。
- 错误通道消重：同一字段同时触发 `WFormValidator.validate()`（边框通道）与
  `formKey.validate()`（内联 `errorText`）时，文案只渲染一次——内联错误优先，
  边框只保留错误态装饰。
- 边框错误改为**按字段错误通道**（`WFormBorderRegistry`，删掉 `GlobalKey` 反查）：
  `setError` / `clearError` 行为不变，字段卸载时通道随之注销；同名字段仍在 debug 抛可读错误。
- `WFormController.formEntered` 改为**由当前字段值实时派生**：不再要求字段调用 `handleChange`，
  自定义字段也能被正确反映。
- `WForm.fieldStyle` 的 `containerPadding` 补齐到下拉字段（之前只有高度 / 文字样式生效）。
- `WFormFieldStyle` 增加 `==` / `hashCode`：字段级样式相等时不再触发无意义子树重建。
- `validate()` 会先执行 `FormBuilderState.save()`：`savedValue` 与当前值同步，字段 `onSaved`
  也会执行（即使校验失败）；文档已注明这个副作用。
- `WFormDatePicker` 在 locale 数据未初始化（未装 `flutter_localizations`）时回退到 `en_US`
  渲染，不再在 build 期抛 `LocaleDataException`。
- 禁用态视觉统一：`WFormCheckbox` / `WFormRadioGroup` 在 `enabled: false` 时整行 0.5 透明度，
  与 `WFormButton` 一致（之前只有图标/文案不变，看不出禁用）。
- 文档：`WForm` / `WFormController` 必须一对一（共用 controller 会 `GlobalKey` 冲突）；
  修正 `textAlign` 直接参数、`WFormTheme` / `WFormScope` 用法。

## 5.1.1

### Fixed
- README 补充表单字段 / 只读 / 弹层 / 输入格式化 / 图标 / 统一校验与 controller 用法；
  example README 移除不存在的 `WFormFieldStyleScope` 示例。

## 5.1.0

### Added
- 直接字段补齐统一外框插槽：`WFormDropdown` / `WFormMultiDropdown` / `WFormDatePicker` /
  `WFormCheckbox` / `WFormRadioGroup` 新增 `leading` / `actions`，`WFormButton` 新增 `actions`。
- `WFormController.reset()`：重置全部字段到初始值（内部走 `formKey.currentState.reset()`）。

### Changed
- `WFormMultiDropdown` 未配置 `hintText` 时不再显示 `ALL`，与 `WFormDropdown` 一致。
  需要旧文案请显式传 `hintText: 'ALL'`。迁移见 `docs/migrations/form-5.1.md`。

### Fixed
- `WFormDatePicker.hintText` 之前只有同时传 `label` 才生效；现在只传 `hintText` 也作为占位符。
- `bordered: false` + `message` / `hintTextList` 在各字段统一断言提示，不再静默丢弃。

## 5.0.0

### Breaking
- 公开入口移除 8 个可变字段 Config；使用直接字段参数 / `WFormFieldStyle`。
- `WForm*Core` 与 `Config.build` 继续作为包内实现，不再属于公开 API。
- 迁移见 `docs/migrations/form-5.0.md`。

## 4.5.0

### Added
- Dropdown/Checkbox/Radio/Multi/Button 直接字段补齐 icon/style/leading 等常用参数，
  高级示例已迁移，减少对可变 Config 的依赖。

## 4.4.0

### Added
- `WFormDatePicker.displayFormat/icon/iconSize` 直接参数，减少对可变 Config 的依赖。

## 4.3.0

### Added
- `WFormTextField.leading`：直接字段覆盖左侧插槽，减少对可变 Config 的依赖。

## 4.2.0

### Deprecated
- 8 个可变字段 Config 标记 deprecated，form 5.0 移除；新代码用直接字段参数 / `WFormFieldStyle`。
  迁移见 `docs/migrations/form-5.0.md`。

## 4.1.0

### Added
- 直接字段新增 `hintText`，明确表示占位符；历史 `label` 继续兼容，`hintText` 优先。
- 修正 `WFormTextFieldConfig` 的“不可变”错误注释（实际为 legacy 可变 Config）。

# Changelog

## 4.0.0

### Removed
- `WFormDefaults`：默认图标改用 `WFormIcons.defaults` / `WFormTheme.icons`。
- `WFormBorderStyleBuilder` + `WFormBorderStyle.builder()`：直接用 `WFormBorderStyle(...)` / `copyWith`。
- `WFormRowBorderExtension`（`Row.withFormBorder`）：直接用 `WFormFieldShell(child: Row(...))`。

## 3.2.0

### Changed
- `WFormTextFieldConfig.build()` 等 5 个 `build()` 与 7 个 `*Core` 类标记 `@internal`，
  并从 `components.dart` 的公共导出中 `hide`：消费方使用会在 `analyze` 报
  `invalid_use_of_internal_member` / 找不到符号。直接字段（`WFormTextField` 等）不受影响。
  4.0 会把组装逻辑物理移出 Config、删除这些符号。

## 3.1.0

### Added
- `WFormIcons`（不可变）：8 个表单图标一名一个字段，`copyWith` 替换；
  `WForm(icons:)` / `WFormTheme(icons:)` 统一替换，单个 `xxxIcon` 参数仍优先。
- `WFormIcons == / hashCode`，值相等。

### Deprecated
- `WFormDefaults`：4.0 移除；改用 `WFormIcons` / `WForm.icons`。它仍作为兜底
  （低于 `WFormTheme.icons`），保留一版用于过渡。

## 3.0.0

### Breaking
- `WForm` 未传 `borderStyle` 时，默认使用 `WFormBorderStyle.fromTheme(Theme.of(context))`：
  字段会有主题边框 / 背景，`message` 与校验错误默认可见（未显式传 `validatorSettings` 时
  `showBorderError = true`）。需要保持「无外观」的页面请显式传 `const WFormBorderStyle()`。
- `WFormTheme` 的优先级改为「显式参数 > 祖先作用域」：嵌套时里层 `WFormTheme(borderStyle:)`
  或 `WForm(borderStyle:)` 说了算（此前祖先会覆盖显式参数）。

### Changed
- 显式 re-export `flutter_form_builder` 的核心类型（`FormBuilderField` / `FormBuilderFieldState` /
  `FormBuilderFields` / `FormBuilderState`）：`WFormController.formKey` / `fields` 与自定义字段
  的公开类型不再“隐式泄漏”，消费方无需自行声明同版本依赖。

### Deprecated
- `WFormBorderStyle.builder()` / `WFormBorderStyleBuilder`：4.0 移除，改用 `WFormBorderStyle(...)` / `copyWith`。
- `Row.withFormBorder(...)`：4.0 移除，改用 `WFormFieldShell(name: ..., child: Row(...))`。

### Fixed
- `WFormTextFieldConfig.build(bordered: false, readOnly: true)` 现在会插入 `WFormReadOnlyScope`（此前与其它字段不一致，消费方插槽读不到只读态）。
- `bordered: false` 时传入 `message` / `hintTextList` 会触发断言，不再静默丢弃。

### Added
- `WFormBorderStyle` / `WFormBorderDecoration` 实现 `==` / `hashCode`；
  `WFormBorderStyle` 新增 `hintStyle` / `errorStyle` 字段（内置工厂用它渲染默认文案，
  不再创建闭包，配置可比较）。

### Changed
- `WFormBorder` 的配置同步改用 `==`，删除内容快照缓存；值相等的配置不会触发重建。

## 2.2.0

### Added
- `WFormBorderStyle.fromTheme(ThemeData)`：边框 / 背景 / 聚焦 / 错误 / 只读底色全部来自 `ColorScheme`，
  hint / error 文字取 `TextTheme.bodySmall`（颜色用 `onSurfaceVariant` / `error`）。深色主题不再白底。
- `WFormBorderStyle.standard()` 的注释明确为「显式浅色预设」，新代码请用 `fromTheme`。

### Changed
- 多选弹层的阴影色默认取 `colorScheme.shadow`，不再写死 `Colors.grey`。

## 2.1.0

### Changed
- 校验设置：`WForm` 只传 `borderStyle` 而未传 `validatorSettings` 时，默认 `showBorderError = true`；此前 `validate()` 失败时界面没有任何反馈。显式传 `validatorSettings` 时完全以显式为准。

### Fixed
- `WFormButton.onTap` 的 `didChange` 在字段已卸载时直接返回，不再对已销毁的字段 `setState`。
- 多选弹层的选项点击同样跳过已卸载字段（弹层挂在 Navigator 上，可能比字段活得久）。
- 同名字段：debug 期先报「字段 name 重复：x」并给出排查方向，不再只剩框架的 GlobalKey 冲突；`WFormController.removeBorderKey` 支持 `owner`，避免同名字段互相删 key。

## 2.0.0

### Changed
- `WFormValidatorSettings` 改为公开可变字段，可直接回读 `showBorderError` / `continueOnError` 等配置。
- 明确 `WFormController.validate`：未挂载返回 false，已挂载空表单返回 true；补空表单测试。
- 新增 `WForm` 容器、`WFormFieldStyle` 默认字段样式与 `validatorSettings` 默认校验设置；config 优先级高于 fieldStyle。
- 修复 `WFormDatePicker` 传 config 时 label hint 丢失、`WFormButton` 传 config 时 hintWidget 被清空。
- 修复直接字段默认值覆盖 config 的 enabled / obscureText / autofocus，以及 label 污染 hintTextList；为 `WFormTextFieldConfig` 增加 hintText / decoration。
- 修复传 config 后整个字段跳过 `WForm.fieldStyle` 的问题；改为按属性合并且 config 优先。
- 移除字段 `borderKey` 参数；边框 key 统一由 `WFormFieldShell` 按 `name` 自动注册，避免重复 GlobalKey。
- 新增直接字段构造 API（`WFormTextField` / `WFormDropdown` / `WFormDatePicker` / `WFormCheckbox` / `WFormRadioGroup` / `WFormButton` 等）。
- 原字段 Widget 重命名为 `*Core` 作为低层实现；普通页面不再需要 `Config.build`。
- 新增登录 / 会员资料可运行示例 `example/`。
- 字段 Config 统一为可变 cascade，继承 `WFormFieldBaseConfig`；`WFormBorderStyle` 保持不可变。
- 移除字段 Config Builder；边框保留 `WFormBorderStyleBuilder`。
- `WFormValidatorConfig` 重命名为 `WFormValidatorSettings`，`validators` / `validate` 参数统一为 `settings`。
- 新增 `WFormController.updateValue`，同时写值并更新输入状态。
- 新增 `WFormController.validate()`；`isAllEntered` 改为显式字段名集合（空集合返回 false）。
- 裸字段 `readOnly` 通过 `WFormReadOnlyScope` 生效；无状态下拉也通过 `WFormFieldCleanup` 清理 `formEntered`。
- `WFormBorder` 可直接读取 `WFormTheme.borderStyle`，不再要求主题必须先于 Scope；改为 `WFormBorderStyleScope`，消除 border / scope / theme 循环 import。
- 新增 `WFormBorderStyle.standard()`，并提供 `WFormTheme.borderStyle` 作用域继承。
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
- 新增边框体系：`WFormBorder` / `WFormBorderStyle` / `WFormBorderWithData` / `WFormReadOnlyScope`
- 新增校验能力：`WFormValidator` / `WFormValidatorItem` / `WFormCustomValidator`
- 新增默认值与输入格式化工具：`WFormDefaults` / `WInputFormatters`
- 支持字段级 `validator` 透传与配置化构建