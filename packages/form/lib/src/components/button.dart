import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border_with_data.dart';
import 'border/read_only_scope.dart';
import 'form_builder.dart';
import 'form_data.dart';

/// 表单按钮组件，用于创建可点击的表单字段
///
/// 按钮本身不展示选项，点击行为由 [onTap] 决定：调用方通过 `didChange`
/// 写入新值，`selectedWidgetBuilder` 负责渲染当前值。
/// 禁用或位于只读作用域时不响应点击，并以半透明样式呈现。
class WFormButton extends StatelessWidget {
  /// 按钮配置
  final WFormButtonConfig config;

  /// 字段名称
  final String name;

  /// 选中值的 widget 构建器
  final Widget Function(String value)? selectedWidgetBuilder;

  /// 点击回调函数
  final void Function(String? value, ValueChanged<String> didChange) onTap;

  /// 初始值
  final String? initialValue;

  /// 是否启用（null 时使用 [WFormButtonConfig] 中的值）
  final bool? enabled;

  /// 校验器
  final FormFieldValidator<String>? validator;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 创建表单按钮组件
  const WFormButton({
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
    return Container(
      height: config._height,
      width: config._width,
      alignment: Alignment.center,
      decoration: config._containerDecoration,
      margin: config._containerMargin,
      padding: config._containerPadding,
      child: Row(
        children: [
          config._leading ?? const SizedBox.shrink(),
          Expanded(
            child: Container(
              transform: config._yOffset != null
                  ? Matrix4.translationValues(0, config._yOffset!, 0)
                  : null,
              child: _WFormBuilderButton<String>(
                name: name,
                initialValue: initialValue,
                enabled: (enabled ?? config._enabled) && !WFormReadOnlyScope.readOnlyOf(context),
                onTap: onTap,
                hintWidget: config._hintWidget,
                selectedWidgetBuilder: selectedWidgetBuilder,
                validator: validator,
                focusNode: focusNode,
              ),
            ),
          ),
          ...?config._actions,
        ],
      ),
    );
  }
}

/// 表单按钮配置类，定义按钮的样式和行为
class WFormButtonConfig {
  /// 提示 widget
  Widget? _hintWidget;

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

  /// 设置提示 widget（null 表示清空）
  set hintWidget(Widget? value) {
    _hintWidget = value;
  }

  /// 设置是否启用
  set enabled(bool value) {
    _enabled = value;
  }

  /// 设置高度（null 表示清空）
  set height(double? value) {
    _height = value;
  }

  /// 设置宽度（null 表示清空）
  set width(double? value) {
    _width = value;
  }

  /// 设置 Y 轴偏移（null 表示清空）
  set yOffset(double? value) {
    _yOffset = value;
  }

  /// 设置左侧组件（null 表示清空）
  set leading(Widget? value) {
    _leading = value;
  }

  /// 设置操作按钮列表（null 表示清空）
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 设置容器装饰（null 表示清空）
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 设置容器边距（null 表示清空）
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 设置容器内边距（null 表示清空）
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
  }

  /// 构建 [WFormButton] 组件
  WFormButton build({
    required String name,
    required void Function(String? value, ValueChanged<String> didChange) onTap,
    Widget Function(String value)? selectedWidgetBuilder,
    String? initialValue,
    bool? enabled,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
  }) {
    return WFormButton(
      config: this,
      name: name,
      onTap: onTap,
      selectedWidgetBuilder: selectedWidgetBuilder,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      focusNode: focusNode,
    );
  }

  /// 构建带有 [WFormBorderWithData] 包装的 [WFormButton] 组件
  ///
  /// 内层容器装饰会被清空，边框交由外层绘制。
  ///
  /// [enabled] 为 null 时读取配置值；最终启用状态为「配置启用 且未只读」。
  /// [readOnly] 为 true 或最终状态为禁用时，内层不可点击、外层使用只读装饰。
  Widget buildBordered({
    required String name,
    required void Function(String? value, ValueChanged<String> didChange) onTap,
    Widget Function(String value)? selectedWidgetBuilder,
    String? initialValue,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    bool? enabled,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
    bool readOnly = false,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }

    final baseEnabled = enabled ?? _enabled;
    final innerConfig = copy()
      ..containerDecoration = null
      ..enabled = baseEnabled && !readOnly;

    return WFormBorderWithData(
      key: key,
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

  /// 创建当前配置的副本
  WFormButtonConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormButtonConfig copyWith({
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
    final config = WFormButtonConfig();
    config._hintWidget = hintWidget ?? _hintWidget;
    config._enabled = enabled ?? _enabled;
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

/// 内部按钮字段，承载表单值、点击与选中态渲染
class _WFormBuilderButton<T> extends FormBuilderField<T> {
  /// 提示 widget
  final Widget? hintWidget;

  /// 选中值的 widget 构建器
  final Widget Function(T value)? selectedWidgetBuilder;

  /// 点击回调函数
  final void Function(T? value, ValueChanged<T> didChange) onTap;

  /// 创建内部按钮字段
  _WFormBuilderButton({
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
           final state = field as FormBuilderFieldState<_WFormBuilderButton<T>, T>;

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
  FormBuilderFieldState<_WFormBuilderButton<T>, T> createState() => _WFormBuilderButtonState<T>();
}

/// 内部按钮字段的状态类
class _WFormBuilderButtonState<T> extends FormBuilderFieldState<_WFormBuilderButton<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormData? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormBuilder.of(context);
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.onChange(widget.name, value);
  }
}
