part of 'multi_dropdown.dart';

class WFormMultiDropdownConfig extends WFormFieldChrome {
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
  /// [bordered] 为 `true` 时返回带 [WFormFieldShell] / [WFormBorder] 的版本，
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
    final baseEnabled = enabled ?? this.enabled;

    // 清空内层容器装饰（在副本上操作，避免污染原配置的后续 build()），边框交由外层 WFormBorder 绘制
    final config = bordered ? (copy()..containerDecoration = null) : this;

    final multiDropdown = WFormMultiDropdown(
      config: config,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      hintText: hintText ?? _hintText,
      width: width,
      enabled: bordered ? baseEnabled && !readOnly : enabled,
    );

    if (!bordered) {
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: multiDropdown) : multiDropdown;
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
    config.enabled = enabled ?? this.enabled;
    config.height = height ?? this.height;
    config.width = width ?? this.width;
    config.yOffset = yOffset ?? this.yOffset;
    config.leading = leading ?? this.leading;
    config.actions = actions ?? this.actions;
    config.containerDecoration = containerDecoration ?? this.containerDecoration;
    config.containerMargin = containerMargin ?? this.containerMargin;
    config.containerPadding = containerPadding ?? this.containerPadding;
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
