part of 'multi_dropdown.dart';

/// 内部多选下拉框组件
class _WFormMultiDropdown<T> extends FormBuilderField<Set<T>> {
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
  final Map<T, String> items;

  /// 未选中状态的复选框图标
  final Widget? checkboxUnselectedIcon;

  /// 选中状态的复选框图标
  final Widget? checkboxSelectedIcon;

  /// 禁用状态的复选框图标
  final Widget? checkboxDisabledIcon;

  /// 文本样式
  final TextStyle? style;

  /// 未选择时占位文本样式
  final TextStyle? hintStyle;

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
  final Set<T> disabledKeys;

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

  /// 交互控件使用的焦点节点（由直接字段的 `focusNode` 传入）
  final FocusNode? interactionFocusNode;

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
    this.hintStyle,
    this.popUpLayerPadding,
    this.popUpLayerElevation,
    this.popUpLayerShadowColor,
    this.hintText,
    this.disabledKeys = const <Never>{},
    this.itemPadding,
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    this.itemTitlePadding,
    this.interactionFocusNode,
  }) : super(
         builder: (FormFieldState<Set<T>?> field) {
           final state = field as _WFormMultiDropdownState<T>;
           final theme = WFormThemeData.of(state.context);

           // 按已选顺序拼接显示文本
           final selectedValues = state.value ?? const <Never>{};
           final title = selectedValues.map((key) => items[key]).whereType<String>().join(', ');

           // 未选择任何项时显示占位文本（未配置 hintText 就不显示）
           final displayText = title.isEmpty ? hintText ?? '' : title;

           void openPopup() {
             WFormPopup.show(
               context: state.context,
               elevation: popUpLayerElevation ?? 10,
               shadowColor: popUpLayerShadowColor ?? Theme.of(state.context).colorScheme.shadow,
               builder: (context) {
                 return Container(
                   width: double.infinity,
                   padding: popUpLayerPadding,
                   child: ValueListenableBuilder<Set<T>>(
                     valueListenable: state.selection,
                     builder: (context, selection, _) => SingleChildScrollView(
                       child: Wrap(
                         children: items.entries.map((e) {
                           // 是否在禁用列表中
                           final bool isDisabled = disabledKeys.contains(e.key);

                           // 显示优先级：选中 > 禁用 > 可用
                           // （已选中的项即使被禁用，也应显示为选中态）
                           _WFormMultiDropdownItemStatus status =
                               _WFormMultiDropdownItemStatus.enable;
                           if (selection.contains(e.key)) {
                             status = _WFormMultiDropdownItemStatus.checked;
                           } else if (isDisabled) {
                             status = _WFormMultiDropdownItemStatus.disable;
                           }

                           return _WFormMultiDropdownItem<T>(
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
                               final selected = <T>{...?state.value};
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
                   ),
                 );
               },
             );
           }

           return FocusableActionDetector(
             enabled: enabled,
             focusNode: state.interactionFocusNode,
             shortcuts: const <ShortcutActivator, Intent>{
               SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
               SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
             },
             actions: <Type, Action<Intent>>{
               ActivateIntent: CallbackAction<ActivateIntent>(
                 onInvoke: (_) {
                   if (enabled) openPopup();
                   return null;
                 },
               ),
             },
             child: Semantics(
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
                     onTap: enabled ? () => openPopup() : null,
                     behavior: HitTestBehavior.translucent,
                     child: Row(
                       children: [
                         Expanded(
                           child: Text(
                             displayText,
                             style: title.isEmpty ? (hintStyle ?? style) : style,
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
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<_WFormMultiDropdown<T>, Set<T>> createState() =>
      _WFormMultiDropdownState<T>();
}

/// 多选字段 state：用 [ValueNotifier] 让已打开的弹层跟随外部值变化。
class _WFormMultiDropdownState<T> extends FormBuilderFieldState<_WFormMultiDropdown<T>, Set<T>> {
  final ValueNotifier<Set<T>> selection = ValueNotifier<Set<T>>(const {});

  /// 未传 external focusNode 时自建的交互节点
  FocusNode? _ownFocusNode;

  /// 交互控件实际使用的焦点节点
  FocusNode get interactionFocusNode =>
      widget.interactionFocusNode ?? (_ownFocusNode ??= FocusNode(debugLabel: widget.name));

  @override
  void focus() => interactionFocusNode.requestFocus();

  @override
  void initState() {
    super.initState();
    selection.value = widget.initialValue ?? const <Never>{};
  }

  @override
  void didChange(Set<T>? value) {
    super.didChange(value);
    selection.value = value ?? const <Never>{};
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    selection.dispose();
    super.dispose();
  }
}

/// 多选下拉框选项状态枚举
