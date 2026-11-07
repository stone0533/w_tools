import 'package:flutter/foundation.dart';
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
/// [displayFormat] 与当前 locale 格式化；
/// 点击后弹出 [showDatePicker] 选择日期。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormDatePickerCore extends FormBuilderField<String> {
  /// 输入装饰（hint / 自定义边框样式）
  final InputDecoration? decoration;

  /// 右侧图标（null 时用箭头）
  final Widget? icon;

  /// 图标大小
  final double? iconSize;

  /// 图标禁用色
  final Color? iconDisabledColor;

  /// 图标启用色
  final Color? iconEnabledColor;

  /// 文本样式
  final TextStyle? style;

  /// 显示格式（字段值始终按 ISO yyyy-MM-dd 存储）
  final String displayFormat;

  /// 外框高度
  final double? height;

  /// 外框宽度
  final double? width;

  /// 内容 Y 轴偏移
  final double? yOffset;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 外框装饰（bordered 时由边框接管）
  final Decoration? containerDecoration;

  /// 外框外边距
  final EdgeInsetsGeometry? containerMargin;

  /// 外框内边距
  final EdgeInsetsGeometry? containerPadding;

  /// 可选择的最早日期
  final DateTime firstDate;

  /// 可选择的最晚日期
  final DateTime lastDate;

  /// 创建日期选择器字段
  WFormDatePickerCore({
    super.key,
    required super.name,
    required this.firstDate,
    required this.lastDate,
    super.initialValue,
    super.validator,
    super.onChanged,
    super.enabled = true,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.onReset,
    super.focusNode,
    this.decoration,
    this.icon,
    this.iconSize,
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
  }) : super(
         builder: (FormFieldState<String?> field) {
           final state = field as FormBuilderFieldState<WFormDatePickerCore, String>;
           final locale = Localizations.localeOf(state.context).toString();

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(state.context);

           // 显示文本
           final date = _tryParse(state.value);
           final title = date == null ? '' : _formatDisplay(date, displayFormat, locale);

           // 容器与图标
           final content = Semantics(
             container: true,
             button: true,
             enabled: isEnabled,
             child: InputDecorator(
               decoration: decoration ?? const InputDecoration(),
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
                           style: style,
                         ),
                       ),
                       icon ??
                           Icon(
                             Icons.arrow_drop_down,
                             size: iconSize,
                             color: isEnabled ? iconEnabledColor : iconDisabledColor,
                           ),
                     ],
                   ),
                 ),
               ),
             ),
           );

           return WFormFieldFrame(
             height: height,
             width: width,
             decoration: containerDecoration,
             margin: containerMargin,
             padding: containerPadding,
             yOffset: yOffset,
             leading: leading,
             actions: actions,
             child: content,
           );
         },
       );

  /// 按显示格式渲染日期；locale 数据未初始化（未装 flutter_localizations）
  /// 时回退到内置的 en_US，避免在 build 期抛 LocaleDataException。
  static String _formatDisplay(DateTime date, String pattern, String locale) {
    try {
      return DateFormat(pattern, locale).format(date);
    } on Exception {
      return DateFormat(pattern, 'en_US').format(date);
    }
  }

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
  FormBuilderFieldState<WFormDatePickerCore, String> createState() => _WFormDatePickerState();
}

/// WFormDatePickerCore 的状态类
class _WFormDatePickerState extends FormBuilderFieldState<WFormDatePickerCore, String> {
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
}
