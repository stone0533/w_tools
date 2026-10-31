import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_chrome.dart';
import '../form_scope.dart';
import '../form_controller.dart';
import '../form_defaults.dart';
import '../form_theme.dart';

/// 单个复选框字段组件
///
/// 点击图标或标题切换选中状态；选中 / 未选中 / 禁用图标、间距与图标偏移可通过
/// [WFormCheckboxConfig] 配置，未配置时取 [WFormDefaults] 的默认图标。
class WFormCheckbox extends FormBuilderField<bool> {
  /// 复选框配置
  final WFormCheckboxConfig config;

  /// 标题 widget（会占满剩余宽度，适合整行布局）
  final Widget? title;

  /// 创建复选框字段
  WFormCheckbox({
    super.key,
    required this.config,
    required super.name,
    required this.title,
    bool super.initialValue = false,
    bool? enabled,
    super.onChanged,
    super.validator,
  }) : super(
         enabled: enabled ?? config.enabled,
         builder: (FormFieldState<bool?> field) {
           final state = field as FormBuilderFieldState<WFormCheckbox, bool>;
           final theme = WFormTheme.maybeOf(field.context);

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(field.context);

           void toggle() {
             if (!isEnabled) {
               return;
             }
             final nextValue = !(state.value ?? false);
             state.didChange(nextValue);
           }

           Widget buildIcon() {
             if (!isEnabled && config.disabledIcon != null) {
               return config.disabledIcon!;
             }
             if (state.value == true) {
               return config.selectedIcon ??
                   theme?.effectiveCheckboxSelectedIcon ??
                   WFormDefaults.checkboxSelectedIcon;
             }
             return config.unselectedIcon ??
                 theme?.effectiveCheckboxUnselectedIcon ??
                 WFormDefaults.checkboxUnselectedIcon;
           }

           return Semantics(
             container: true,
             checked: state.value == true,
             enabled: isEnabled,
             child: WFormFieldFrame(
               height: config.height,
               width: config.width,
               decoration: config.containerDecoration,
               margin: config.containerMargin,
               padding: config.containerPadding,
               leading: config.leading,
               actions: config.actions,
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   MouseRegion(
                     cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                     child: GestureDetector(
                       behavior: HitTestBehavior.opaque,
                       onTap: toggle,
                       child: Transform(
                         transform: Matrix4.translationValues(0, config.iconYOffset ?? 0, 0),
                         child: buildIcon(),
                       ),
                     ),
                   ),
                   SizedBox(width: config.iconSpacing ?? 0),
                   Expanded(
                     child: MouseRegion(
                       cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                       child: GestureDetector(
                         behavior: HitTestBehavior.opaque,
                         onTap: toggle,
                         child: title,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormCheckbox, bool> createState() => _WFormCheckboxState();
}

/// WFormCheckbox 的状态类
class _WFormCheckboxState extends FormBuilderFieldState<WFormCheckbox, bool> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormScope.of(context);
  }

  @override
  void didChange(bool? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.handleChange(widget.name, value);
  }

  @override
  void dispose() {
    _formData?.removeFormEntered(widget.name);
    super.dispose();
  }
}

/// 复选框配置类，定义复选框的样式和行为。
///
/// 可变的字段配置；需要链式构建时为 [builder]。
class WFormCheckboxConfig extends WFormFieldChrome {
  Widget? unselectedIcon;
  Widget? selectedIcon;
  Widget? disabledIcon;
  double? iconSpacing;
  double? iconYOffset;

  WFormCheckboxConfig({
    this.unselectedIcon,
    this.selectedIcon,
    this.disabledIcon,
    this.iconSpacing,
    this.iconYOffset,
    bool enabled = true,
    double? height,
    double? width,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    this.enabled = enabled;
    this.height = height;
    this.width = width;
    this.leading = leading;
    this.actions = actions;
    this.containerDecoration = containerDecoration;
    this.containerMargin = containerMargin;
    this.containerPadding = containerPadding;
  }

  Widget build({
    required String name,
    required Widget title,
    bool initialValue = false,
    bool? enabled,
    ValueChanged<bool?>? onChanged,
    FormFieldValidator<bool>? validator,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? this.enabled;
    final config = bordered ? (copy()..containerDecoration = null) : this;
    final field = WFormCheckbox(
      config: config,
      name: name,
      title: title,
      initialValue: initialValue,
      enabled: bordered ? baseEnabled && !readOnly : enabled,
      onChanged: onChanged,
      validator: validator,
    );
    if (!bordered) {
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: field) : field;
    }
    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly || !baseEnabled,
      child: field,
    );
  }

  WFormCheckboxConfig copy() => copyWith();

  WFormCheckboxConfig copyWith({
    Widget? unselectedIcon,
    Widget? selectedIcon,
    Widget? disabledIcon,
    double? iconSpacing,
    double? iconYOffset,
    bool? enabled,
    double? height,
    double? width,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    return WFormCheckboxConfig(
      unselectedIcon: unselectedIcon ?? this.unselectedIcon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      disabledIcon: disabledIcon ?? this.disabledIcon,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      iconYOffset: iconYOffset ?? this.iconYOffset,
      enabled: enabled ?? this.enabled,
      height: height ?? this.height,
      width: width ?? this.width,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
    );
  }
}

/// [WFormCheckboxConfig] 的 Builder；返回可变配置副本。
