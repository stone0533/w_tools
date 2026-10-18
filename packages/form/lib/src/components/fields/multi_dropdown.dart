import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_builder.dart';
import '../form_defaults.dart';
import '../popup.dart';

/// 表单多选下拉框组件
///
/// 点击后在锚点下方弹出可多选的选项列表，字段值为 `Set<String>`；
/// 未选择时的占位文本、禁用项、弹层外观与选项样式可通过
/// [WFormMultiDropdownConfig] 配置，只读状态会合并外层 [WFormReadOnlyScope]。
class WFormMultiDropdown extends StatelessWidget {
  /// 多选下拉框配置
  final WFormMultiDropdownConfig config;

  /// 字段名称
  final String name;

  /// 选项映射，键为值，值为显示文本
  final Map<String, String> items;

  /// 初始值
  final Set<String>? initialValue;

  /// 值变化回调（空集合表示未选择）
  final ValueChanged<Set<String>>? onChanged;

  /// 校验器
  final FormFieldValidator<Set<String>>? validator;

  /// 未选择时的展示文本（null 时使用 config.hintText，仍未配置则显示 `ALL`）
  final String? hintText;

  /// 宽度（null 时使用 config.width）
  final double? width;

  /// 是否启用（null 时使用 config.enabled）
  final bool? enabled;

  /// 创建多选下拉框组件
  const WFormMultiDropdown({
    super.key,
    required this.config,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.hintText,
    this.width,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final wFormData = WFormBuilder.requireOf(context);

    void onChangedHandler(Set<String>? value) {
      final selected = value ?? const <String>{};
      wFormData.onChange(name, selected);
      onChanged?.call(selected);
    }

    return WFormFieldFrame(
      height: config._height,
      width: width ?? config._width,
      decoration: config._containerDecoration,
      margin: config._containerMargin,
      padding: config._containerPadding,
      yOffset: config._yOffset,
      leading: config._leading,
      actions: config._actions,
      child: _WFormMultiDropdown(
        name: name,
        items: items,
        initialValue: initialValue,
        onChanged: onChangedHandler,
        validator: validator,
        enabled: (enabled ?? config._enabled) && !WFormReadOnlyScope.readOnlyOf(context),
        decoration: config._decoration,
        icon: config._icon,
        iconSize: config._iconSize,
        iconDisabledColor: config._iconDisabledColor,
        iconEnabledColor: config._iconEnabledColor,
        checkboxUnselectedIcon: config._checkboxUnselectedIcon,
        checkboxSelectedIcon: config._checkboxSelectedIcon,
        checkboxDisabledIcon: config._checkboxDisabledIcon,
        style: config._style,
        popUpLayerPadding: config._popUpLayerPadding,
        popUpLayerElevation: config._popUpLayerElevation,
        popUpLayerShadowColor: config._popUpLayerShadowColor,
        hintText: hintText ?? config._hintText,
        disabledKeys: config._disabledKeys,
        itemPadding: config._itemPadding,
        itemStyle: config._itemStyle,
        itemCheckedStyle: config._itemCheckedStyle,
        itemDisabledStyle: config._itemDisabledStyle,
        itemTitlePadding: config._itemTitlePadding,
      ),
    );
  }
}

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
                             shadowColor: popUpLayerShadowColor ?? Colors.grey,
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
                                             WFormDefaults.checkboxUnselectedIcon,
                                         checkedIcon:
                                             checkboxSelectedIcon ??
                                             WFormDefaults.checkboxSelectedIcon,
                                         disabledIcon: checkboxDisabledIcon,
                                         status: status,
                                         onTap: (v, isChecked) {
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
                         child: icon ?? WFormDefaults.dropdownIcon,
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
enum _WFormMultiDropdownItemStatus {
  /// 启用状态
  enable,

  /// 选中状态
  checked,

  /// 禁用状态
  disable,
}

/// 多选下拉框选项点击回调
typedef _WFormMultiDropdownItemTapCallback = void Function(String value, bool isChecked);

/// 多选下拉框选项组件
class _WFormMultiDropdownItem extends StatefulWidget {
  /// 选项值
  final String value;

  /// 选项标题
  final String title;

  /// 标题内边距
  final EdgeInsetsGeometry? titlePadding;

  /// 选项状态
  final _WFormMultiDropdownItemStatus status;

  /// 是否禁用（与 [status] 分离：已禁用的项若已选中，仍显示选中态但不可点击）
  final bool disabled;

  /// 点击回调
  final _WFormMultiDropdownItemTapCallback onTap;

  /// 文本样式
  final TextStyle? style;

  /// 选中状态文本样式
  final TextStyle? checkedStyle;

  /// 禁用状态文本样式
  final TextStyle? disabledStyle;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 未选中状态图标
  final Widget icon;

  /// 选中状态图标
  final Widget checkedIcon;

  /// 禁用状态图标
  final Widget? disabledIcon;

  /// 创建选项组件
  const _WFormMultiDropdownItem({
    required this.value,
    required this.title,
    this.titlePadding,
    this.status = _WFormMultiDropdownItemStatus.enable,
    this.disabled = false,
    required this.onTap,
    this.padding,
    this.style,
    this.checkedStyle,
    this.disabledStyle,
    required this.icon,
    required this.checkedIcon,
    this.disabledIcon,
  });

  @override
  State<_WFormMultiDropdownItem> createState() => _WFormMultiDropdownItemState();
}

/// _WFormMultiDropdownItem 的状态类
class _WFormMultiDropdownItemState extends State<_WFormMultiDropdownItem> {
  /// 是否选中
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.status == _WFormMultiDropdownItemStatus.checked;
  }

  @override
  void didUpdateWidget(covariant _WFormMultiDropdownItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部值变化（回填 / 重置）后，让本地选中态重新跟随 status
    if (widget.status != oldWidget.status) {
      isChecked = widget.status == _WFormMultiDropdownItemStatus.checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.status == _WFormMultiDropdownItemStatus.disable;

    return Semantics(
      container: true,
      checked: isChecked,
      enabled: !isDisabled,
      child: MouseRegion(
        cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (isDisabled) {
              return;
            }
            setState(() {
              isChecked = !isChecked;
            });
            widget.onTap.call(widget.value, isChecked);
          },
          child: Container(
            padding: widget.padding ?? EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.status == _WFormMultiDropdownItemStatus.disable
                    ? widget.disabledIcon ?? widget.icon
                    : isChecked
                    ? widget.checkedIcon
                    : widget.icon,
                Padding(
                  padding: widget.titlePadding ?? const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.title,
                    style: widget.status == _WFormMultiDropdownItemStatus.disable
                        ? widget.disabledStyle ?? widget.style
                        : isChecked
                        ? widget.checkedStyle ?? widget.style
                        : widget.style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 多选下拉框配置类，定义多选下拉框的样式和行为
class WFormMultiDropdownConfig {
  /// 是否启用
  bool _enabled = true;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// Y 轴偏移
  double? _yOffset;

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

  /// 输入装饰
  InputDecoration? _decoration;

  /// 图标大小
  double? _iconSize = 24;

  /// 下拉按钮图标
  Widget? _icon;

  /// 禁用状态图标颜色
  Color? _iconDisabledColor;

  /// 启用状态图标颜色
  Color? _iconEnabledColor;

  /// 未选中状态的复选框图标
  Widget? _checkboxUnselectedIcon;

  /// 选中状态的复选框图标
  Widget? _checkboxSelectedIcon;

  /// 禁用状态的复选框图标
  Widget? _checkboxDisabledIcon;

  /// 文本样式
  TextStyle? _style;

  /// 弹出层内边距
  EdgeInsets? _popUpLayerPadding;

  /// 弹出层阴影高度
  double? _popUpLayerElevation;

  /// 弹出层阴影颜色
  Color? _popUpLayerShadowColor;

  /// 未选择时的展示文本
  String? _hintText;

  /// 禁用的键
  Set<String> _disabledKeys = const <String>{};

  /// 选项项内边距
  EdgeInsetsGeometry? _itemPadding;

  /// 选项项标题样式
  TextStyle? _itemStyle;

  /// 选项项选中状态标题样式
  TextStyle? _itemCheckedStyle;

  /// 选项项禁用状态标题样式
  TextStyle? _itemDisabledStyle;

  /// 选项项标题内边距
  EdgeInsets? _itemTitlePadding;

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

  /// 设置 Y 轴偏移
  set yOffset(double? value) {
    _yOffset = value;
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

  /// 设置输入装饰
  set decoration(InputDecoration? value) {
    _decoration = value;
  }

  /// 设置图标大小（null 表示使用默认大小）
  set iconSize(double? value) {
    _iconSize = value;
  }

  /// 设置下拉按钮图标
  set icon(Widget? value) {
    _icon = value;
  }

  /// 设置禁用状态图标颜色
  set iconDisabledColor(Color? value) {
    _iconDisabledColor = value;
  }

  /// 设置启用状态图标颜色
  set iconEnabledColor(Color? value) {
    _iconEnabledColor = value;
  }

  /// 设置未选中状态的复选框图标
  set checkboxUnselectedIcon(Widget? value) {
    _checkboxUnselectedIcon = value;
  }

  /// 设置选中状态的复选框图标
  set checkboxSelectedIcon(Widget? value) {
    _checkboxSelectedIcon = value;
  }

  /// 设置禁用状态的复选框图标
  set checkboxDisabledIcon(Widget? value) {
    _checkboxDisabledIcon = value;
  }

  /// 设置文本样式
  set style(TextStyle? value) {
    _style = value;
  }

  /// 设置弹出层内边距
  set popUpLayerPadding(EdgeInsets? value) {
    _popUpLayerPadding = value;
  }

  /// 设置弹出层阴影高度
  set popUpLayerElevation(double? value) {
    _popUpLayerElevation = value;
  }

  /// 设置弹出层阴影颜色
  set popUpLayerShadowColor(Color? value) {
    _popUpLayerShadowColor = value;
  }

  /// 设置未选择时的展示文本
  set hintText(String? value) {
    _hintText = value;
  }

  /// 设置禁用的键（null 表示清空）
  set disabledKeys(Set<String>? value) {
    _disabledKeys = value ?? const <String>{};
  }

  /// 设置选项项内边距
  set itemPadding(EdgeInsetsGeometry? value) {
    _itemPadding = value;
  }

  /// 设置选项项标题样式
  set itemStyle(TextStyle? value) {
    _itemStyle = value;
  }

  /// 设置选项项选中状态标题样式
  set itemCheckedStyle(TextStyle? value) {
    _itemCheckedStyle = value;
  }

  /// 设置选项项禁用状态标题样式
  set itemDisabledStyle(TextStyle? value) {
    _itemDisabledStyle = value;
  }

  /// 设置选项项标题内边距
  set itemTitlePadding(EdgeInsets? value) {
    _itemTitlePadding = value;
  }

  /// 构建 [WFormMultiDropdown] 组件
  ///
  /// [bordered] 为 `true` 时返回带 [WFormBorderWithData] / [WFormBorder] 的版本，
  /// 内层 `containerDecoration` 会被清空，边框交由外层绘制；否则返回裸字段。
  ///
  /// [readOnly] 为 true 时内层控件不可交互、外层使用只读装饰；
  /// [enabled]（配置项）为 false 时外层同样按只读展示。
  Widget build({
    required String name,
    required Map<String, String> items,
    Set<String>? initialValue,
    ValueChanged<Set<String>>? onChanged,
    FormFieldValidator<Set<String>>? validator,
    String? hintText,
    double? width,
    bool? enabled,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? _enabled;

    // 清空内层容器装饰（在副本上操作，避免污染原配置的后续 build()），边框交由外层 WFormBorder 绘制
    final config = bordered ? (copy()..containerDecoration = null) : this;

    final multiDropdown = WFormMultiDropdown(
      config: config,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      hintText: hintText,
      width: width,
      enabled: bordered ? baseEnabled && !readOnly : enabled,
    );

    if (!bordered) {
      return multiDropdown;
    }

    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly || !baseEnabled,
      child: multiDropdown,
    );
  }

  /// 创建当前配置的副本
  WFormMultiDropdownConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormMultiDropdownConfig copyWith({
    bool? enabled,
    double? height,
    double? width,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    InputDecoration? decoration,
    double? iconSize,
    Widget? icon,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    Widget? checkboxUnselectedIcon,
    Widget? checkboxSelectedIcon,
    Widget? checkboxDisabledIcon,
    TextStyle? style,
    EdgeInsets? popUpLayerPadding,
    double? popUpLayerElevation,
    Color? popUpLayerShadowColor,
    String? hintText,
    Set<String>? disabledKeys,
    EdgeInsetsGeometry? itemPadding,
    TextStyle? itemStyle,
    TextStyle? itemCheckedStyle,
    TextStyle? itemDisabledStyle,
    EdgeInsets? itemTitlePadding,
  }) {
    final config = WFormMultiDropdownConfig();
    config._enabled = enabled ?? _enabled;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._decoration = decoration ?? _decoration;
    config._iconSize = iconSize ?? _iconSize;
    config._icon = icon ?? _icon;
    config._iconDisabledColor = iconDisabledColor ?? _iconDisabledColor;
    config._iconEnabledColor = iconEnabledColor ?? _iconEnabledColor;
    config._checkboxUnselectedIcon = checkboxUnselectedIcon ?? _checkboxUnselectedIcon;
    config._checkboxSelectedIcon = checkboxSelectedIcon ?? _checkboxSelectedIcon;
    config._checkboxDisabledIcon = checkboxDisabledIcon ?? _checkboxDisabledIcon;
    config._style = style ?? _style;
    config._popUpLayerPadding = popUpLayerPadding ?? _popUpLayerPadding;
    config._popUpLayerElevation = popUpLayerElevation ?? _popUpLayerElevation;
    config._popUpLayerShadowColor = popUpLayerShadowColor ?? _popUpLayerShadowColor;
    config._hintText = hintText ?? _hintText;
    config._disabledKeys = disabledKeys ?? _disabledKeys;
    config._itemPadding = itemPadding ?? _itemPadding;
    config._itemStyle = itemStyle ?? _itemStyle;
    config._itemCheckedStyle = itemCheckedStyle ?? _itemCheckedStyle;
    config._itemDisabledStyle = itemDisabledStyle ?? _itemDisabledStyle;
    config._itemTitlePadding = itemTitlePadding ?? _itemTitlePadding;
    return config;
  }
}
