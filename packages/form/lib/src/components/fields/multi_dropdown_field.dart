part of 'multi_dropdown.dart';

/// 内部多选下拉框组件
class _WFormMultiDropdown extends FormBuilderField<Set<String>> {
  /// 图标大小
  final double? iconSize;

  /// 下拉按钮图标的 widget
  ///
  /// 默认是带有 [Icons.arrow_drop_down] 图标的 [Icon]。
  final Widget? icon;

  /// 当按钮禁用时，[icon] 的任何 [Icon] 后代的颜色
  final Color? iconDisabledColor;

  /// 当按钮启用时，[icon] 的任何 [Icon] 后代的颜色
  final Color? iconEnabledColor;

  /// 选项映射，键为值，值为显示文本
  final Map<String, String> items;

  /// 未选中状态的复选框图标
  final Widget? checkboxUnselectedIcon;

  /// 选中状态的复选框图标
  final Widget? checkboxSelectedIcon;

  /// 禁用状态的复选框图标
  final Widget? checkboxDisabledIcon;

  /// 文本样式
  final TextStyle? style;

  /// 输入装饰
  final InputDecoration? decoration;

  /// 弹出层内边距
  final EdgeInsets? popUpLayerPadding;

  /// 弹出层阴影高度
  final double? popUpLayerElevation;

  /// 弹出层阴影颜色
  final Color? popUpLayerShadowColor;

  /// 未选择时的展示文本
  final String? hintText;

  /// 禁用的键
  final Set<String> disabledKeys;

  /// 选项项内边距
  final EdgeInsetsGeometry? itemPadding;

  /// 选项项标题样式
  final TextStyle? itemStyle;

  /// 选项项选中状态标题样式
  final TextStyle? itemCheckedStyle;

  /// 选项项禁用状态标题样式
  final TextStyle? itemDisabledStyle;

  /// 选项项标题内边距
  final EdgeInsets? itemTitlePadding;

  /// 创建内部多选下拉框字段
  _WFormMultiDropdown({
    required super.name,
    super.initialValue,
    super.onChanged,
    super.validator,
    super.enabled,
    this.decoration,
    this.icon,
    this.iconSize = 24,
    this.iconDisabledColor,
    this.iconEnabledColor,
    required this.items,
    this.checkboxUnselectedIcon,
    this.checkboxSelectedIcon,
    this.checkboxDisabledIcon,
    this.style,
    this.popUpLayerPadding,
    this.popUpLayerElevation,
    this.popUpLayerShadowColor,
    this.hintText,
    this.disabledKeys = const <String>{},
    this.itemPadding,
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    this.itemTitlePadding,
  }) : super(
         builder: (FormFieldState<Set<String>?> field) {
           final state = field as FormBuilderFieldState<_WFormMultiDropdown, Set<String>>;
           final theme = WFormTheme.maybeOf(state.context);

           // 按已选顺序拼接显示文本
           final selectedValues = state.value ?? const <String>{};
           final title = selectedValues.map((key) => items[key]).whereType<String>().join(', ');

           // 未选择任何项时显示占位文本
           final displayText = title.isEmpty ? hintText ?? 'ALL' : title;

           return Semantics(
             container: true,
             button: true,
             enabled: enabled,
             child: InputDecorator(
               isEmpty: title.isEmpty,
               decoration:
                   decoration ??
                   const InputDecoration(
                     border: InputBorder.none,
                     focusedBorder: InputBorder.none,
                     enabledBorder: InputBorder.none,
                   ),
               child: MouseRegion(
                 cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                 child: GestureDetector(
                   onTap: enabled
                       ? () {
                           WFormPopup.show(
                             context: state.context,
                             elevation: popUpLayerElevation ?? 10,
                             shadowColor:
                                 popUpLayerShadowColor ??
                                 Theme.of(state.context).colorScheme.shadow,
                             builder: (context) {
                               return Container(
                                 width: double.infinity,
                                 padding: popUpLayerPadding,
                                 child: SingleChildScrollView(
                                   child: Wrap(
                                     children: items.entries.map((e) {
                                       // 是否在禁用列表中
                                       final bool isDisabled = disabledKeys.contains(e.key);

                                       // 显示优先级：选中 > 禁用 > 可用
                                       // （已选中的项即使被禁用，也应显示为选中态）
                                       _WFormMultiDropdownItemStatus status =
                                           _WFormMultiDropdownItemStatus.enable;
                                       if (state.value?.contains(e.key) ?? false) {
                                         status = _WFormMultiDropdownItemStatus.checked;
                                       } else if (isDisabled) {
                                         status = _WFormMultiDropdownItemStatus.disable;
                                       }

                                       return _WFormMultiDropdownItem(
                                         value: e.key,
                                         title: e.value,
                                         disabled: isDisabled,
                                         icon:
                                             checkboxUnselectedIcon ??
                                             theme?.effectiveCheckboxUnselectedIcon ??
                                             WFormIcons.defaults.checkboxUnselected,
                                         checkedIcon:
                                             checkboxSelectedIcon ??
                                             theme?.effectiveCheckboxSelectedIcon ??
                                             WFormIcons.defaults.checkboxSelected,
                                         disabledIcon: checkboxDisabledIcon,
                                         status: status,
                                         onTap: (v, isChecked) {
                                           // 弹层挂在 Navigator 上，可能比字段活得久
                                           if (!state.mounted) return;
                                           final selected = <String>{...?state.value};
                                           if (isChecked) {
                                             selected.add(v);
                                           } else {
                                             selected.remove(v);
                                           }
                                           state.didChange(selected);
                                         },
                                         titlePadding: itemTitlePadding,
                                         style: itemStyle,
                                         padding: itemPadding,
                                         checkedStyle: itemCheckedStyle,
                                         disabledStyle: itemDisabledStyle,
                                       );
                                     }).toList(),
                                   ),
                                 ),
                               );
                             },
                           );
                         }
                       : null,
                   behavior: HitTestBehavior.translucent,
                   child: Row(
                     children: [
                       Expanded(
                         child: Text(
                           displayText,
                           style: style,
                           strutStyle: style != null
                               ? StrutStyle(
                                   fontFamily: style.fontFamily,
                                   fontWeight: style.fontWeight,
                                   fontSize: style.fontSize,
                                   leading: 0,
                                   forceStrutHeight: true,
                                   height: 1.3,
                                 )
                               : null,
                         ),
                       ),
                       IconTheme(
                         data: IconThemeData(
                           size: iconSize,
                           color: enabled ? iconEnabledColor : iconDisabledColor,
                         ),
                         child:
                             icon ?? theme?.effectiveDropdownIcon ?? WFormIcons.defaults.dropdown,
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<_WFormMultiDropdown, Set<String>> createState() =>
      FormBuilderFieldState<_WFormMultiDropdown, Set<String>>();
}

/// 多选下拉框选项状态枚举
