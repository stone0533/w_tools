// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/read_only_scope.dart';
import 'field_base_config.dart';
import 'field_frame.dart';
import 'form_scope.dart';
import 'form_controller.dart';

/// 表单按钮组件，用于创建可点击的表单字段
///
/// 按钮本身不展示选项，点击行为由 [onTap] 决定：调用方通过 `didChange`
/// 写入新值，`selectedWidgetBuilder` 负责渲染当前值。
/// 禁用或位于只读作用域时不响应点击，并以半透明样式呈现。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormFieldButtonCore extends StatelessWidget {
  /// 按钮配置
  final WFormFieldButtonConfig config;

  /// 字段名称
  final String name;

  /// 选中值的 widget 构建器
  final Widget Function(String value)? selectedWidgetBuilder;

  /// 点击回调函数
  final void Function(String? value, ValueChanged<String> didChange) onTap;

  /// 初始值
  final String? initialValue;

  /// 是否启用（null 时使用 [WFormFieldButtonConfig] 中的值）
  final bool? enabled;

  /// 校验器
  final FormFieldValidator<String>? validator;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 创建表单按钮组件
  const WFormFieldButtonCore({
    super.key,
    required this.config,
    required this.name,
    required this.onTap,
    this.selectedWidgetBuilder,
    this.initialValue,
    this.enabled,
    this.validator,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return WFormFieldFrame(
      height: config.height,
      width: config.width,
      decoration: config.containerDecoration,
      margin: config.containerMargin,
      padding: config.containerPadding,
      yOffset: config.yOffset,
      leading: config.leading,
      actions: config.actions,
      child: _WFormScopeButton<String>(
        name: name,
        initialValue: initialValue,
        enabled: (enabled ?? config.enabled) && !WFormReadOnlyScope.readOnlyOf(context),
        onTap: onTap,
        hintWidget: config.hintWidget,
        selectedWidgetBuilder: selectedWidgetBuilder,
        validator: validator,
        focusNode: focusNode,
      ),
    );
  }
}

/// 表单按钮配置类，定义按钮的样式和行为。
///
/// 可变的字段配置；用命名构造 / copyWith。
class WFormFieldButtonConfig extends WFormFieldBaseConfig {
  Widget? hintWidget;

  WFormFieldButtonConfig({
    this.hintWidget,
    bool enabled = true,
    double? height,
    double? width,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
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
    required void Function(String? value, ValueChanged<String> didChange) onTap,
    Widget Function(String value)? selectedWidgetBuilder,
    String? initialValue,
    bool? enabled,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    bool readOnly = false,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool enableFocusBorder = true,
  }) {
    if (!bordered) {
      // message / hintTextList 只由边框渲染；无边框时静默丢弃是陷阱，直接报出来
      assert(
        hintTextList == null || hintTextList.isEmpty,
        'bordered: false 时不会渲染 message / hintTextList；需要提示请保留 bordered，或自行展示。',
      );
      final field = WFormFieldButtonCore(
        config: this,
        name: name,
        onTap: onTap,
        selectedWidgetBuilder: selectedWidgetBuilder,
        initialValue: initialValue,
        enabled: enabled,
        validator: validator,
        focusNode: focusNode,
      );
      return readOnly ? WFormReadOnlyScope(readOnly: true, child: field) : field;
    }

    final baseEnabled = enabled ?? this.enabled;
    final innerConfig = copy()
      ..containerDecoration = null
      ..enabled = baseEnabled && !readOnly;

    return WFormFieldFrame.border(
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly || !baseEnabled,
      enableFocusBorder: enableFocusBorder,
      child: innerConfig.build(
        name: name,
        onTap: onTap,
        selectedWidgetBuilder: selectedWidgetBuilder,
        initialValue: initialValue,
        validator: validator,
        focusNode: focusNode,
      ),
    );
  }

  WFormFieldButtonConfig copy() => copyWith();

  WFormFieldButtonConfig copyWith({
    Widget? hintWidget,
    bool? enabled,
    double? height,
    double? width,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    return WFormFieldButtonConfig(
      hintWidget: hintWidget ?? this.hintWidget,
      enabled: enabled ?? this.enabled,
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

/// 内部按钮字段，承载表单值、点击与选中态渲染
class _WFormScopeButton<T> extends FormBuilderField<T> {
  /// 提示 widget
  final Widget? hintWidget;

  /// 选中值的 widget 构建器
  final Widget Function(T value)? selectedWidgetBuilder;

  /// 点击回调函数
  final void Function(T? value, ValueChanged<T> didChange) onTap;

  /// 创建内部按钮字段
  _WFormScopeButton({
    super.key,
    required super.name,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.valueTransformer,
    super.enabled,
    super.onSaved,
    super.onReset,
    super.focusNode,
    super.restorationId,
    this.selectedWidgetBuilder,
    required this.onTap,
    this.hintWidget,
  }) : super(
         builder: (FormFieldState<T?> field) {
           final state = field as FormBuilderFieldState<_WFormScopeButton<T>, T>;

           final T? value = state.value;
           final Widget content = value == null
               ? hintWidget ?? const SizedBox.shrink()
               : selectedWidgetBuilder?.call(value) ?? const SizedBox.shrink();

           return Semantics(
             button: true,
             enabled: state.enabled,
             child: Material(
               type: MaterialType.transparency,
               child: InkWell(
                 onTap: state.enabled
                     ? () => onTap.call(state.value, (a) {
                         // 消费方通常在 await 选择器后调用 didChange；
                         // 期间字段可能已卸载，直接写会 setState after dispose。
                         if (!state.mounted) return;
                         state.didChange(a);
                       })
                     : null,
                 mouseCursor: state.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                 canRequestFocus: state.enabled,
                 child: Opacity(
                   opacity: state.enabled ? 1 : 0.5,
                   child: content,
                 ),
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<_WFormScopeButton<T>, T> createState() => _WFormScopeButtonState<T>();
}

/// 内部按钮字段的状态类
class _WFormScopeButtonState<T> extends FormBuilderFieldState<_WFormScopeButton<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormScope.of(context);
  }

  @override
  void didChange(T? value) {
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
