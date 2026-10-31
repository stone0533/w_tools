import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_base_config.dart';
import '../form_scope.dart';
import '../form_controller.dart';
import '../form_defaults.dart';
import '../form_theme.dart';

/// 表单单选按钮组组件
///
/// 以单列布局渲染所有选项，支持自定义标题（[titleBuilder]）与选项下方
/// 附加内容（[itemExtraBuilder]）；选中状态、间距与图标可通过
/// [WFormRadioGroupConfig] 配置，只读状态会合并外层 [WFormReadOnlyScope]。
class WFormRadioGroupCore<T> extends FormBuilderField<T> {
  /// 单选按钮组配置
  final WFormRadioGroupConfig config;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 自定义标题构建器
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;

  /// 自定义附加内容构建器（显示在每个选项下方）
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;

  /// 创建单选按钮组字段
  WFormRadioGroupCore({
    super.key,
    required this.config,
    required super.name,
    required this.items,
    this.titleBuilder,
    this.itemExtraBuilder,
    super.initialValue,
    bool? enabled,
    super.onChanged,
    super.validator,
  }) : super(
         enabled: enabled ?? config.enabled,
         builder: (FormFieldState<T?> field) {
           final state = field as FormBuilderFieldState<WFormRadioGroupCore<T>, T>;
           final theme = WFormTheme.maybeOf(field.context);

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(field.context);

           void click(T v) {
             if (!isEnabled) {
               return;
             }
             state.didChange(v);
           }

           final options = Padding(
             padding: config.containerPadding ?? EdgeInsets.zero,
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               spacing: config.lineSpacing ?? 0,
               children: items.entries.map((element) {
                 final isSelected = state.value == element.key;

                 Widget? child = itemExtraBuilder != null
                     ? itemExtraBuilder(field.context, element.key, element.value, isSelected)
                     : null;

                 return Semantics(
                   container: true,
                   checked: isSelected,
                   inMutuallyExclusiveGroup: true,
                   enabled: isEnabled,
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           MouseRegion(
                             cursor: isEnabled
                                 ? SystemMouseCursors.click
                                 : SystemMouseCursors.basic,
                             child: GestureDetector(
                               behavior: HitTestBehavior.opaque,
                               onTap: () => click(element.key),
                               child: Transform(
                                 transform: Matrix4.translationValues(
                                   0,
                                   config.iconYOffset ?? 0,
                                   0,
                                 ),
                                 child: isSelected
                                     ? config.selectedIcon ??
                                           theme?.effectiveRadioSelectedIcon ??
                                           WFormDefaults.radioSelectedIcon
                                     : config.unselectedIcon ??
                                           theme?.effectiveRadioUnselectedIcon ??
                                           WFormDefaults.radioUnselectedIcon,
                               ),
                             ),
                           ),
                           SizedBox(width: config.iconSpacing ?? 0),
                           Expanded(
                             child: MouseRegion(
                               cursor: isEnabled
                                   ? SystemMouseCursors.click
                                   : SystemMouseCursors.basic,
                               child: GestureDetector(
                                 behavior: HitTestBehavior.opaque,
                                 onTap: () => click(element.key),
                                 child: titleBuilder != null
                                     ? titleBuilder(
                                         field.context,
                                         element.key,
                                         element.value,
                                         isSelected,
                                       )
                                     : Text(
                                         element.value,
                                         style: config.style,
                                         strutStyle: StrutStyle(
                                           fontFamily: config.style?.fontFamily,
                                           fontSize: config.style?.fontSize,
                                           fontWeight: config.style?.fontWeight,
                                           height: config.style?.height,
                                           forceStrutHeight: true,
                                         ),
                                       ),
                               ),
                             ),
                           ),
                         ],
                       ),
                       if (child != null) child,
                     ],
                   ),
                 );
               }).toList(),
             ),
           );

           return WFormFieldFrame(
             height: config.height,
             width: config.width,
             decoration: config.containerDecoration,
             margin: config.containerMargin,
             // containerPadding 作用在内层选项 Padding 上，外框不再重复施加
             padding: null,
             leading: config.leading,
             actions: config.actions,
             child: options,
           );
         },
       );

  @override
  FormBuilderFieldState<WFormRadioGroupCore<T>, T> createState() => _WFormRadioGroupState<T>();
}

/// WFormRadioGroupCore 的状态类
class _WFormRadioGroupState<T> extends FormBuilderFieldState<WFormRadioGroupCore<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormScope.of(context);
  }

  @override
  void didChange(T? value) {
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

/// 单选按钮组配置类，定义单选按钮组的样式和行为。
///
/// 可变的字段配置；需要链式构建时为 [builder]。
class WFormRadioGroupConfig extends WFormFieldBaseConfig {
  Widget? unselectedIcon;
  Widget? selectedIcon;
  double? iconSpacing;
  double? lineSpacing;
  double? iconYOffset;
  TextStyle? style;

  WFormRadioGroupConfig({
    this.unselectedIcon,
    this.selectedIcon,
    this.iconSpacing,
    this.lineSpacing,
    this.iconYOffset,
    this.style,
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

  Widget build<T>({
    required String name,
    required Map<T, String> items,
    Widget Function(BuildContext, T, String, bool)? titleBuilder,
    Widget Function(BuildContext, T, String, bool)? itemExtraBuilder,
    T? initialValue,
    bool? enabled,
    ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? this.enabled;
    final config = bordered ? (copy()..containerDecoration = null) : this;
    final field = WFormRadioGroupCore<T>(
      config: config,
      name: name,
      items: items,
      titleBuilder: titleBuilder,
      itemExtraBuilder: itemExtraBuilder,
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

  WFormRadioGroupConfig copy() => copyWith();

  WFormRadioGroupConfig copyWith({
    Widget? unselectedIcon,
    Widget? selectedIcon,
    double? iconSpacing,
    double? lineSpacing,
    double? iconYOffset,
    bool? enabled,
    double? height,
    double? width,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    TextStyle? style,
  }) {
    return WFormRadioGroupConfig(
      unselectedIcon: unselectedIcon ?? this.unselectedIcon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      iconYOffset: iconYOffset ?? this.iconYOffset,
      enabled: enabled ?? this.enabled,
      height: height ?? this.height,
      width: width ?? this.width,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
      style: style ?? this.style,
    );
  }
}

/// [WFormRadioGroupConfig] 的 Builder；返回可变配置副本。
