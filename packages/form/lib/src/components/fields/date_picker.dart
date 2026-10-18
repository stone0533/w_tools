import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_builder.dart';
import '../form_data.dart';

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
         enabled: enabled ?? config._enabled,
         builder: (FormFieldState<String?> field) {
           final state = field as FormBuilderFieldState<WFormDatePicker, String>;
           final locale = Localizations.localeOf(state.context).toString();

           // 继承外层只读作用域（WFormBorderWithData.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(state.context);

           // 显示文本
           final date = _tryParse(state.value);
           final title = date == null ? '' : DateFormat(config._displayFormat, locale).format(date);

           // 容器与图标
           final content = Semantics(
             container: true,
             button: true,
             enabled: isEnabled,
             child: InputDecorator(
               decoration: config._decoration ?? const InputDecoration(),
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
                           style: config._style,
                         ),
                       ),
                       config._icon ??
                           Icon(
                             Icons.arrow_drop_down,
                             size: config._iconSize,
                             color: isEnabled
                                 ? config._iconEnabledColor
                                 : config._iconDisabledColor,
                           ),
                     ],
                   ),
                 ),
               ),
             ),
           );

           return WFormFieldFrame(
             height: config._height,
             width: config._width,
             decoration: config._containerDecoration,
             margin: config._containerMargin,
             padding: config._containerPadding,
             yOffset: config._yOffset,
             leading: config._leading,
             actions: config._actions,
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
  WFormData? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormBuilder.of(context);
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.onChange(widget.name, value);
  }
}

/// 日期选择器配置类，定义日期选择器的样式和行为
class WFormDatePickerConfig {
  /// 是否启用
  bool _enabled = true;

  /// 输入装饰
  InputDecoration? _decoration = const InputDecoration();

  /// 右侧图标
  Widget? _icon;

  /// 图标大小
  double? _iconSize = 24;

  /// 禁用状态图标颜色（仅作用于默认图标）
  Color? _iconDisabledColor;

  /// 启用状态图标颜色（仅作用于默认图标）
  Color? _iconEnabledColor;

  /// 文本样式
  TextStyle? _style;

  /// 展示格式（[DateFormat] pattern，默认 `yMMMMd`）
  String _displayFormat = 'yMMMMd';

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

  /// 设置是否启用
  set enabled(bool value) {
    _enabled = value;
  }

  /// 设置输入装饰（null 表示不渲染装饰）
  set decoration(InputDecoration? value) {
    _decoration = value;
  }

  /// 设置右侧图标
  set icon(Widget? value) {
    _icon = value;
  }

  /// 设置图标大小（null 表示使用默认大小）
  set iconSize(double? value) {
    _iconSize = value;
  }

  /// 设置禁用状态图标颜色
  set iconDisabledColor(Color? value) {
    _iconDisabledColor = value;
  }

  /// 设置启用状态图标颜色
  set iconEnabledColor(Color? value) {
    _iconEnabledColor = value;
  }

  /// 设置文本样式
  set style(TextStyle? value) {
    _style = value;
  }

  /// 设置展示格式（[DateFormat] pattern）
  set displayFormat(String value) {
    _displayFormat = value;
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

  /// 构建 [WFormDatePicker] 组件
  ///
  /// [enabled] 为 null 时使用配置中的值。
  ///
  /// [bordered] 为 `true` 时返回带 [WFormBorderWithData] / [WFormBorder] 的版本，
  /// 内层 `containerDecoration` 会被清空，边框交由外层绘制；否则返回裸字段。
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
      return WFormDatePicker(
        config: this,
        name: name,
        firstDate: firstDate,
        lastDate: lastDate,
        initialValue: initialValue,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
      );
    }

    final baseEnabled = enabled ?? _enabled;
    final innerConfig = copy()..containerDecoration = null;

    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly || !baseEnabled,
      enableFocusBorder: enableFocusBorder,
      child: innerConfig.build(
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

  /// 创建当前配置的副本
  WFormDatePickerConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
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
    final config = WFormDatePickerConfig();
    config._enabled = enabled ?? _enabled;
    config._decoration = decoration ?? _decoration;
    config._icon = icon ?? _icon;
    config._iconSize = iconSize ?? _iconSize;
    config._iconDisabledColor = iconDisabledColor ?? _iconDisabledColor;
    config._iconEnabledColor = iconEnabledColor ?? _iconEnabledColor;
    config._style = style ?? _style;
    config._displayFormat = displayFormat ?? _displayFormat;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    return config;
  }
}
