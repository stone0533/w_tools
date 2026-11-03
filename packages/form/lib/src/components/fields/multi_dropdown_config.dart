part of 'multi_dropdown.dart';

class WFormMultiDropdownConfig extends WFormFieldBaseConfig {
  InputDecoration? decoration;
  double? iconSize;
  Widget? icon;
  Color? iconDisabledColor;
  Color? iconEnabledColor;
  Widget? checkboxUnselectedIcon;
  Widget? checkboxSelectedIcon;
  Widget? checkboxDisabledIcon;
  TextStyle? style;
  EdgeInsets? popUpLayerPadding;
  double? popUpLayerElevation;
  Color? popUpLayerShadowColor;
  String? hintText;
  Set<String> disabledKeys;
  EdgeInsetsGeometry? itemPadding;
  TextStyle? itemStyle;
  TextStyle? itemCheckedStyle;
  TextStyle? itemDisabledStyle;
  EdgeInsets? itemTitlePadding;

  WFormMultiDropdownConfig({
    bool enabled = true,
    double? height,
    double? width,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    this.decoration,
    this.iconSize = 24,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
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
  }) {
    this.enabled = enabled;
    this.height = height;
    this.width = width;
    this.yOffset = yOffset;
    this.leading = leading;
    this.actions = actions;
    this.containerDecoration = containerDecoration;
    this.containerMargin = containerMargin;
    this.containerPadding = containerPadding;
  }

  /// 框架内部使用（直接字段 / Core 组装），4.0 物理移出 Config。
  @internal
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
    bool enableFocusBorder = true,
  }) {
    final baseEnabled = enabled ?? this.enabled;
    final config = bordered ? (copy()..containerDecoration = null) : this;

    final multiDropdown = WFormMultiDropdownCore(
      config: config,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      hintText: hintText ?? this.hintText,
      width: width,
      enabled: bordered ? baseEnabled && !readOnly : enabled,
    );

    if (!bordered) {
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: multiDropdown) : multiDropdown;
    }

    return WFormFieldFrame.border(
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: readOnly || !baseEnabled,
      child: multiDropdown,
    );
  }

  WFormMultiDropdownConfig copy() => copyWith();

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
    return WFormMultiDropdownConfig(
      enabled: enabled ?? this.enabled,
      height: height ?? this.height,
      width: width ?? this.width,
      yOffset: yOffset ?? this.yOffset,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
      decoration: decoration ?? this.decoration,
      iconSize: iconSize ?? this.iconSize,
      icon: icon ?? this.icon,
      iconDisabledColor: iconDisabledColor ?? this.iconDisabledColor,
      iconEnabledColor: iconEnabledColor ?? this.iconEnabledColor,
      checkboxUnselectedIcon: checkboxUnselectedIcon ?? this.checkboxUnselectedIcon,
      checkboxSelectedIcon: checkboxSelectedIcon ?? this.checkboxSelectedIcon,
      checkboxDisabledIcon: checkboxDisabledIcon ?? this.checkboxDisabledIcon,
      style: style ?? this.style,
      popUpLayerPadding: popUpLayerPadding ?? this.popUpLayerPadding,
      popUpLayerElevation: popUpLayerElevation ?? this.popUpLayerElevation,
      popUpLayerShadowColor: popUpLayerShadowColor ?? this.popUpLayerShadowColor,
      hintText: hintText ?? this.hintText,
      disabledKeys: disabledKeys ?? this.disabledKeys,
      itemPadding: itemPadding ?? this.itemPadding,
      itemStyle: itemStyle ?? this.itemStyle,
      itemCheckedStyle: itemCheckedStyle ?? this.itemCheckedStyle,
      itemDisabledStyle: itemDisabledStyle ?? this.itemDisabledStyle,
      itemTitlePadding: itemTitlePadding ?? this.itemTitlePadding,
    );
  }
}
