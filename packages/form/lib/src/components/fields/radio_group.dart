import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/border_with_data.dart';
import '../border/read_only_scope.dart';
import '../form_builder.dart';
import '../form_data.dart';
import '../form_defaults.dart';

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
         enabled: enabled ?? config._enabled,
         builder: (FormFieldState<T?> field) {
           final state = field as FormBuilderFieldState<WFormRadioGroup<T>, T>;

           // 继承外层只读作用域（WFormBorderWithData.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(field.context);

           void click(T v) {
             if (!isEnabled) {
               return;
             }
             state.didChange(v);
           }

           final options = Padding(
             padding: config._containerPadding ?? EdgeInsets.zero,
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
                                     ? config._selectedIcon ?? WFormDefaults.radioSelectedIcon
                                     : config._unselectedIcon ?? WFormDefaults.radioUnselectedIcon,
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

           return Container(
             height: config._height,
             width: config._width,
             alignment: Alignment.center,
             decoration: config._containerDecoration,
             margin: config._containerMargin,
             child: Row(
               children: [
                 config._leading ?? const SizedBox.shrink(),
                 Expanded(child: options),
                 ...?config._actions,
               ],
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormRadioGroup<T>, T> createState() => _WFormRadioGroupState<T>();
}

/// WFormRadioGroup 的状态类
class _WFormRadioGroupState<T> extends FormBuilderFieldState<WFormRadioGroup<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormData? _formData;

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
class WFormRadioGroupConfig {
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

  /// 是否启用
  bool _enabled = true;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// 左侧组件
  Widget? _leading;

  /// 操作按钮列表
  List<Widget>? _actions;

  /// 容器装饰
  Decoration? _containerDecoration;

  /// 容器边距
  EdgeInsetsGeometry? _containerMargin;

  /// 容器内边距
  EdgeInsetsGeometry? _containerPadding;

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

  /// 设置是否启用
  set enabled(bool value) {
    _enabled = value;
  }

  /// 设置高度
  set height(double? value) {
    _height = value;
  }

  /// 设置宽度
  set width(double? value) {
    _width = value;
  }

  /// 设置左侧组件
  set leading(Widget? value) {
    _leading = value;
  }

  /// 设置操作按钮列表
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 设置容器装饰
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 设置容器边距
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 设置容器内边距
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
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
  WFormRadioGroup<T> build<T>({
    required String name,
    required Map<T, String> items,
    Widget Function(BuildContext, T, String, bool)? titleBuilder,
    Widget Function(BuildContext, T, String, bool)? itemExtraBuilder,
    T? initialValue,
    bool? enabled,
    ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
  }) {
    return WFormRadioGroup<T>(
      config: this,
      name: name,
      items: items,
      titleBuilder: titleBuilder,
      itemExtraBuilder: itemExtraBuilder,
      initialValue: initialValue,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// 构建带有 [WFormBorderWithData] 包装的 [WFormRadioGroup] 组件
  ///
  /// 内层容器装饰会被清空，边框交由外层绘制。
  /// [readOnly] 为 true 时内层不可交互、外层使用只读装饰。
  Widget buildBordered<T>({
    required String name,
    required Map<T, String> items,
    Widget Function(BuildContext, T, String, bool)? titleBuilder,
    Widget Function(BuildContext, T, String, bool)? itemExtraBuilder,
    T? initialValue,
    bool? enabled,
    ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
    bool readOnly = false,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }

    final baseEnabled = enabled ?? _enabled;
    final innerConfig = copy()..containerDecoration = null;

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly || !baseEnabled,
      enableFocusBorder: enableFocusBorder,
      child: innerConfig.build<T>(
        name: name,
        items: items,
        titleBuilder: titleBuilder,
        itemExtraBuilder: itemExtraBuilder,
        initialValue: initialValue,
        enabled: baseEnabled && !readOnly,
        onChanged: onChanged,
        validator: validator,
      ),
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
    config._enabled = enabled ?? _enabled;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._style = style ?? _style;
    return config;
  }
}
