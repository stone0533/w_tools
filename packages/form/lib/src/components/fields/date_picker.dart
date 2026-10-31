import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_controller.dart';

/// 表单日期选择器组件
///
/// 字段值以 ISO `yyyy-MM-dd` 存储（与 locale 无关），显示时按
/// [WFormDatePickerConfig.displayFormat] 与当前 locale 格式化；
/// 点击后弹出 [showDatePicker] 选择日期。
class WFormDatePicker extends FormBuilderField<String> {
  /// 日期选择器配置
  final WFormDatePickerConfig config;

  /// 可选择的最早日期
  final DateTime firstDate;

  /// 可选择的最晚日期
  final DateTime lastDate;

  /// 创建日期选择器字段
  WFormDatePicker({
    super.key,
    required this.config,
    required super.name,
    required this.firstDate,
    required this.lastDate,
    super.initialValue,
    super.validator,
    super.onChanged,
    bool? enabled,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.onReset,
    super.focusNode,
  }) : super(
         enabled: enabled ?? config.enabled,
         builder: (FormFieldState<String?> field) {
           final state = field as FormBuilderFieldState<WFormDatePicker, String>;
           final locale = Localizations.localeOf(state.context).toString();

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(state.context);

           // 显示文本
           final date = _tryParse(state.value);
           final title = date == null ? '' : DateFormat(config.displayFormat, locale).format(date);

           // 容器与图标
           final content = Semantics(
             container: true,
             button: true,
             enabled: isEnabled,
             child: InputDecorator(
               decoration: config.decoration ?? const InputDecoration(),
               isEmpty: date == null,
               child: MouseRegion(
                 cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                 child: GestureDetector(
                   onTap: isEnabled
                       ? () {
                           // 解析初始日期并 clamp 到 [firstDate, lastDate]
                           DateTime? initDate = _tryParse(state.value);
                           if (initDate != null) {
                             if (initDate.isBefore(firstDate)) {
                               initDate = firstDate;
                             } else if (initDate.isAfter(lastDate)) {
                               initDate = lastDate;
                             }
                           }

                           showDatePicker(
                             context: state.context,
                             firstDate: firstDate,
                             lastDate: lastDate,
                             initialDate: initDate,
                           ).then((value) {
                             if (!state.mounted || value == null) {
                               return;
                             }
                             final formatted = _formatStorage(value);
                             state.didChange(formatted);
                           });
                         }
                       : null,
                   behavior: HitTestBehavior.translucent,
                   child: Row(
                     children: [
                       Expanded(
                         child: Text(
                           title,
                           style: config.style,
                         ),
                       ),
                       config.icon ??
                           Icon(
                             Icons.arrow_drop_down,
                             size: config.iconSize,
                             color: isEnabled ? config.iconEnabledColor : config.iconDisabledColor,
                           ),
                     ],
                   ),
                 ),
               ),
             ),
           );

           return WFormFieldFrame(
             height: config.height,
             width: config.width,
             decoration: config.containerDecoration,
             margin: config.containerMargin,
             padding: config.containerPadding,
             yOffset: config.yOffset,
             leading: config.leading,
             actions: config.actions,
             child: content,
           );
         },
       );

  /// 按 ISO `yyyy-MM-dd` 存储日期
  static String _formatStorage(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  /// 解析 ISO `yyyy-MM-dd` 日期字符串，失败返回 null
  static DateTime? _tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  FormBuilderFieldState<WFormDatePicker, String> createState() => _WFormDatePickerState();
}

/// WFormDatePicker 的状态类
class _WFormDatePickerState extends FormBuilderFieldState<WFormDatePicker, String> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormScope.of(context);
  }

  @override
  void didChange(String? value) {
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

/// 日期选择器配置类，定义日期选择器的样式和行为。
///
/// 本类已迁移为不可变配置；需要链式构建时使用 [builder]。
class WFormDatePickerConfig {
  static WFormDatePickerConfigBuilder builder() => WFormDatePickerConfigBuilder();

  final bool enabled;
  final InputDecoration? decoration;
  final Widget? icon;
  final double? iconSize;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final TextStyle? style;
  final String displayFormat;
  final double? height;
  final double? width;
  final double? yOffset;
  final Widget? leading;
  final List<Widget>? actions;
  final Decoration? containerDecoration;
  final EdgeInsetsGeometry? containerMargin;
  final EdgeInsetsGeometry? containerPadding;

  const WFormDatePickerConfig({
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.icon,
    this.iconSize = 24,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.style,
    this.displayFormat = 'yMMMMd',
    this.height,
    this.width,
    this.yOffset,
    this.leading,
    this.actions,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
  });

  /// 构建 [WFormDatePicker] 组件
  Widget build({
    required String name,
    required DateTime firstDate,
    required DateTime lastDate,
    String? initialValue,
    FormFieldValidator<String>? validator,
    ValueChanged<String?>? onChanged,
    bool? enabled,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    if (!bordered) {
      final field = WFormDatePicker(
        config: this,
        name: name,
        firstDate: firstDate,
        lastDate: lastDate,
        initialValue: initialValue,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
      );
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: field) : field;
    }

    final baseEnabled = enabled ?? this.enabled;
    final innerConfig = WFormDatePickerConfigBuilder.from(this)..containerDecoration = null;

    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly || !baseEnabled,
      enableFocusBorder: enableFocusBorder,
      child: innerConfig.buildConfig().build(
        name: name,
        firstDate: firstDate,
        lastDate: lastDate,
        initialValue: initialValue,
        validator: validator,
        onChanged: onChanged,
        enabled: baseEnabled && !readOnly,
      ),
    );
  }

  WFormDatePickerConfig copy() => copyWith();

  /// 参数为 null 表示沿用原值；清空可先用 [builder] 或 [WFormDatePickerConfigBuilder]。
  WFormDatePickerConfig copyWith({
    bool? enabled,
    InputDecoration? decoration,
    Widget? icon,
    double? iconSize,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    TextStyle? style,
    String? displayFormat,
    double? height,
    double? width,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    return WFormDatePickerConfig(
      enabled: enabled ?? this.enabled,
      decoration: decoration ?? this.decoration,
      icon: icon ?? this.icon,
      iconSize: iconSize ?? this.iconSize,
      iconDisabledColor: iconDisabledColor ?? this.iconDisabledColor,
      iconEnabledColor: iconEnabledColor ?? this.iconEnabledColor,
      style: style ?? this.style,
      displayFormat: displayFormat ?? this.displayFormat,
      height: height ?? this.height,
      width: width ?? this.width,
      yOffset: yOffset ?? this.yOffset,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
    );
  }
}

/// [WFormDatePickerConfig] 的 Builder，最后通过 [buildConfig] 产出不可变配置。
class WFormDatePickerConfigBuilder {
  bool enabled = true;
  InputDecoration? decoration = const InputDecoration();
  Widget? icon;
  double? iconSize = 24;
  Color? iconDisabledColor;
  Color? iconEnabledColor;
  TextStyle? style;
  String displayFormat = 'yMMMMd';
  double? height;
  double? width;
  double? yOffset;
  Widget? leading;
  List<Widget>? actions;
  Decoration? containerDecoration;
  EdgeInsetsGeometry? containerMargin;
  EdgeInsetsGeometry? containerPadding;

  WFormDatePickerConfigBuilder();

  WFormDatePickerConfigBuilder.from(WFormDatePickerConfig config)
    : enabled = config.enabled,
      decoration = config.decoration,
      icon = config.icon,
      iconSize = config.iconSize,
      iconDisabledColor = config.iconDisabledColor,
      iconEnabledColor = config.iconEnabledColor,
      style = config.style,
      displayFormat = config.displayFormat,
      height = config.height,
      width = config.width,
      yOffset = config.yOffset,
      leading = config.leading,
      actions = config.actions,
      containerDecoration = config.containerDecoration,
      containerMargin = config.containerMargin,
      containerPadding = config.containerPadding;

  WFormDatePickerConfig buildConfig() {
    return WFormDatePickerConfig(
      enabled: enabled,
      decoration: decoration,
      icon: icon,
      iconSize: iconSize,
      iconDisabledColor: iconDisabledColor,
      iconEnabledColor: iconEnabledColor,
      style: style,
      displayFormat: displayFormat,
      height: height,
      width: width,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      containerDecoration: containerDecoration,
      containerMargin: containerMargin,
      containerPadding: containerPadding,
    );
  }
}
