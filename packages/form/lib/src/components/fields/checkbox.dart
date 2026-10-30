import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_controller.dart';
import '../field_chrome.dart';
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
             if (!isEnabled && config._disabledIcon != null) {
               return config._disabledIcon!;
             }
             if (state.value == true) {
               return config._selectedIcon ??
                   theme?.effectiveCheckboxSelectedIcon ??
                   WFormDefaults.checkboxSelectedIcon;
             }
             return config._unselectedIcon ??
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
                         transform: Matrix4.translationValues(0, config._iconYOffset ?? 0, 0),
                         child: buildIcon(),
                       ),
                     ),
                   ),
                   SizedBox(width: config._iconSpacing ?? 0),
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
}

/// 复选框配置类，定义复选框的样式和行为
class WFormCheckboxConfig extends WFormFieldChrome {
  /// 未选中状态的图标
  Widget? _unselectedIcon;

  /// 选中状态的图标
  Widget? _selectedIcon;

  /// 禁用状态的图标
  Widget? _disabledIcon;

  /// 图标与标题之间的间距
  double? _iconSpacing;

  /// 图标 Y 轴偏移
  double? _iconYOffset;

  /// 设置禁用状态图标（null 表示使用默认）
  set disabledIcon(Widget? value) {
    _disabledIcon = value;
  }

  /// 设置未选中状态图标（null 表示使用默认图标）
  set unselectedIcon(Widget? value) {
    _unselectedIcon = value;
  }

  /// 设置选中状态图标（null 表示使用默认图标）
  set selectedIcon(Widget? value) {
    _selectedIcon = value;
  }

  /// 设置图标与标题之间的间距（null 表示无额外间距）
  set iconSpacing(double? value) {
    _iconSpacing = value;
  }

  /// 设置图标 Y 轴偏移（null 表示不偏移）
  set iconYOffset(double? value) {
    _iconYOffset = value;
  }

  /// 构建 [WFormCheckbox] 组件
  ///
  /// [enabled] 为 null 时使用配置中的值。
  ///
  /// [bordered] 为 `true` 时返回带 [WFormFieldShell] / [WFormBorder] 的版本，
  /// 内层 `containerDecoration` 会被清空，边框交由外层绘制；否则返回裸字段。
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
      return field;
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

  /// 创建当前配置的副本
  WFormCheckboxConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
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
    final config = WFormCheckboxConfig();
    config._unselectedIcon = unselectedIcon ?? _unselectedIcon;
    config._selectedIcon = selectedIcon ?? _selectedIcon;
    config._disabledIcon = disabledIcon ?? _disabledIcon;
    config._iconSpacing = iconSpacing ?? _iconSpacing;
    config._iconYOffset = iconYOffset ?? _iconYOffset;
    config.enabled = enabled ?? this.enabled;
    config.height = height ?? this.height;
    config.width = width ?? this.width;
    config.leading = leading ?? this.leading;
    config.actions = actions ?? this.actions;
    config.containerDecoration = containerDecoration ?? this.containerDecoration;
    config.containerMargin = containerMargin ?? this.containerMargin;
    config.containerPadding = containerPadding ?? this.containerPadding;
    return config;
  }
}
