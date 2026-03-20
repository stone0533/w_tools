import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

/// 表单日期选择器组件
class FormBuilderDatePicker extends FormBuilderField<String> {
  /// 图标大小
  final double iconSize;

  /// 下拉按钮图标的 widget
  ///
  /// 默认是带有 [Icons.arrow_drop_down] 图标的 [Icon]。
  final Widget? icon;

  /// 当按钮禁用时，[icon] 的任何 [Icon] 后代的颜色
  ///
  /// 当主题的 [ThemeData.brightness] 为 [Brightness.light] 时默认为 [Colors.grey.shade400]，
  /// 当为 [Brightness.dark] 时默认为 [Colors.white10]
  final Color? iconDisabledColor;

  /// 当按钮启用时，[icon] 的任何 [Icon] 后代的颜色
  ///
  /// 当主题的 [ThemeData.brightness] 为 [Brightness.light] 时默认为 [Colors.grey.shade700]，
  /// 当为 [Brightness.dark] 时默认为 [Colors.white70]
  final Color? iconEnabledColor;

  /// 文本样式
  final TextStyle? style;

  /// 可选择的最早日期
  final DateTime firstDate;

  /// 可选择的最晚日期
  final DateTime lastDate;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param name 字段名称
  /// @param validator 验证器
  /// @param initialValue 初始值
  /// @param decoration 输入装饰
  /// @param onChanged 值变化回调
  /// @param valueTransformer 值转换器
  /// @param enabled 是否启用
  /// @param onSaved 保存回调
  /// @param autovalidateMode 自动验证模式
  /// @param onReset 重置回调
  /// @param focusNode 焦点节点
  /// @param icon 下拉按钮图标
  /// @param iconSize 图标大小
  /// @param iconDisabledColor 禁用状态图标颜色
  /// @param iconEnabledColor 启用状态图标颜色
  /// @param style 文本样式
  /// @param firstDate 可选择的最早日期
  /// @param lastDate 可选择的最晚日期
  FormBuilderDatePicker({
    super.key,
    required super.name,
    super.validator,
    super.initialValue,
    InputDecoration decoration = const InputDecoration(),
    super.onChanged,
    super.valueTransformer,
    super.enabled,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.onReset,
    super.focusNode,
    this.icon,
    this.iconSize = 24,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.style,
    required this.firstDate,
    required this.lastDate,
  }) : super(
         builder: (FormFieldState<String?> field) {
           final state = field as _FormBuilderDatePickerState;

           // 格式化显示日期
           String title = '';
           if (state.value?.isNotEmpty ?? false) {
             DateTime date = DateFormat.yMEd().parse(state.value!);
             var formatter = DateFormat.yMMMMd('en_US');
             title = formatter.format(date);
           }

           return InputDecorator(
             decoration: decoration,
             child: GestureDetector(
               onTap: () {
                 // 解析初始日期
                 DateTime? initDate;
                 if (state.value?.isNotEmpty ?? false) {
                   initDate = DateFormat.yMEd().parse(state.value!);
                 }

                 // 显示日期选择器
                 showDatePicker(
                   context: state.context,
                   firstDate: firstDate,
                   lastDate: lastDate,
                   initialDate: initDate,
                 ).then((value) {
                   if (value == null) {
                     state.setValue(null);
                   } else {
                     var formatter = DateFormat.yMEd();
                     String formatted = formatter.format(value);
                     state.setValue(formatted);
                   }
                 });
               },
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
                         color: enabled ? iconEnabledColor : iconDisabledColor,
                       ),
                 ],
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<FormBuilderDatePicker, String> createState() =>
      _FormBuilderDatePickerState();
}

/// FormBuilderDatePicker 的状态类
class _FormBuilderDatePickerState extends FormBuilderFieldState<FormBuilderDatePicker, String> {}
