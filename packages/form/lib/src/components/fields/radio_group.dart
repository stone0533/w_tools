import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_builder.dart';
import '../form_controller.dart';
import '../field_chrome.dart';
import '../form_defaults.dart';
import '../form_theme.dart';

/// 表单单选按钮组组件
///
/// 以单列布局渲染所有选项，支持自定义标题（[titleBuilder]）与选项下方
/// 附加内容（[itemExtraBuilder]）；选中状态、间距与图标可通过
/// [WFormRadioGroupConfig] 配置，只读状态会合并外层 [WFormReadOnlyScope]。
class WFormRadioGroup<T> extends FormBuilderField<T> {
  /// 单选按钮组配置
  final WFormRadioGroupConfig config;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 自定义标题构建器
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;

  /// 自定义附加内容构建器（显示在每个选项下方）
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;

  /// 创建单选按钮组字段
  WFormRadioGroup({
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
           final state = field as FormBuilderFieldState<WFormRadioGroup<T>, T>;
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
               spacing: config._lineSpacing ?? 0,
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
                                   config._iconYOffset ?? 0,
                                   0,
                                 ),
                                 child: isSelected
                                     ? config._selectedIcon ??
                                           theme?.effectiveRadioSelectedIcon ??
                                           WFormDefaults.radioSelectedIcon
                                     : config._unselectedIcon ??
                                           theme?.effectiveRadioUnselectedIcon ??
                                           WFormDefaults.radioUnselectedIcon,
                               ),
                             ),
                           ),
                           SizedBox(width: config._iconSpacing ?? 0),
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
                                         style: config._style,
                                         strutStyle: StrutStyle(
                                           fontFamily: config._style?.fontFamily,
                                           fontSize: config._style?.fontSize,
                                           fontWeight: config._style?.fontWeight,
                                           height: config._style?.height,
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
  FormBuilderFieldState<WFormRadioGroup<T>, T> createState() => _WFormRadioGroupState<T>();
}

/// WFormRadioGroup 的状态类
class _WFormRadioGroupState<T> extends FormBuilderFieldState<WFormRadioGroup<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormBuilder.of(context);
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.onChange(widget.name, value);
  }
}

/// 单选按钮组配置类，定义单选按钮组的样式和行为
class WFormRadioGroupConfig extends WFormFieldChrome {
  /// 未选中状态的图标
  Widget? _unselectedIcon;

  /// 选中状态的图标
  Widget? _selectedIcon;

  /// 图标与文本之间的间距
  double? _iconSpacing;

  /// 行间距
  double? _lineSpacing;

  /// 图标 Y 轴偏移
  double? _iconYOffset;

  /// 文本样式
  TextStyle? _style;

  /// 设置未选中状态图标（null 表示使用默认图标）
  set unselectedIcon(Widget? value) {
    _unselectedIcon = value;
  }

  /// 设置选中状态图标（null 表示使用默认图标）
  set selectedIcon(Widget? value) {
    _selectedIcon = value;
  }

  /// 设置图标与文本之间的间距（null 表示无额外间距）
  set iconSpacing(double? value) {
    _iconSpacing = value;
  }

  /// 设置图标 Y 轴偏移（null 表示不偏移）
  set iconYOffset(double? value) {
    _iconYOffset = value;
  }

  /// 设置行间距（null 表示无额外间距）
  set lineSpacing(double? value) {
    _lineSpacing = value;
  }

  /// 设置文本样式
  set style(TextStyle? value) {
    _style = value;
  }

  /// 构建 [WFormRadioGroup] 组件
  ///
  /// [enabled] 为 null 时使用配置中的值。
  ///
  /// [bordered] 为 `true` 时返回带 [WFormFieldShell] / [WFormBorder] 的版本，
  /// 内层 `containerDecoration` 会被清空，边框交由外层绘制；否则返回裸字段。
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
    final field = WFormRadioGroup<T>(
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
  WFormRadioGroupConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
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
    final config = WFormRadioGroupConfig();
    config._unselectedIcon = unselectedIcon ?? _unselectedIcon;
    config._selectedIcon = selectedIcon ?? _selectedIcon;
    config._iconSpacing = iconSpacing ?? _iconSpacing;
    config._lineSpacing = lineSpacing ?? _lineSpacing;
    config._iconYOffset = iconYOffset ?? _iconYOffset;
    config.enabled = enabled ?? this.enabled;
    config.height = height ?? this.height;
    config.width = width ?? this.width;
    config.leading = leading ?? this.leading;
    config.actions = actions ?? this.actions;
    config.containerDecoration = containerDecoration ?? this.containerDecoration;
    config.containerMargin = containerMargin ?? this.containerMargin;
    config.containerPadding = containerPadding ?? this.containerPadding;
    config._style = style ?? _style;
    return config;
  }
}
