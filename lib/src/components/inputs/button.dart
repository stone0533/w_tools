import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// 表单按钮组件，用于创建可点击的表单字段
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

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 按钮配置
  /// @param name 字段名称
  /// @param onTap 点击回调函数
  /// @param selectedWidgetBuilder 选中值的 widget 构建器
  /// @param initialValue 初始值
  const WFormButton({
    super.key,
    required this.config,
    required this.name,
    required this.onTap,
    this.selectedWidgetBuilder,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: config._height,
      alignment: Alignment.center,
      decoration: config._containerDecoration,
      margin: config._containerMargin,
      padding: config._containerPadding,
      child: Row(
        children: [
          config._leading ?? Container(),
          Expanded(
            child: Container(
              transform: config._yOffset != null
                  ? Matrix4.translationValues(0, config._yOffset!, 0)
                  : null,
              child: _WFormBuilderButton<String>(
                name: name,
                initialValue: initialValue,
                enabled: config._enabled,
                onTap: onTap,
                hintWidget: config._hintWidget,
                selectedWidgetBuilder: selectedWidgetBuilder,
              ),
            ),
          ),
          ...?config._actions?.map(
            (action) => Container(
              height: config._height,
              alignment: Alignment.center,
              child: action,
            ),
          ),
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

  /// Y轴偏移
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

  /// 提示 widget setter
  set hintWidget(Widget value) {
    _hintWidget = value;
  }

  /// 是否启用 setter
  set enabled(bool value) {
    _enabled = value;
  }

  /// 高度 setter
  set height(double value) {
    _height = value;
  }

  /// Y轴偏移 setter
  set yOffset(double value) {
    _yOffset = value;
  }

  /// 左侧组件 setter
  set leading(Widget value) {
    _leading = value;
  }

  /// 操作按钮列表 setter
  set actions(List<Widget> value) {
    _actions = value;
  }

  /// 容器装饰 setter
  set containerDecoration(Decoration value) {
    _containerDecoration = value;
  }

  /// 容器边距 setter
  set containerMargin(EdgeInsetsGeometry value) {
    _containerMargin = value;
  }

  /// 容器内边距 setter
  set containerPadding(EdgeInsetsGeometry value) {
    _containerPadding = value;
  }

  /// 构建 WFormButton 组件
  ///
  /// @param name 字段名称
  /// @param onTap 点击回调函数
  /// @param selectedWidgetBuilder 选中值的 widget 构建器
  /// @param initialValue 初始值
  /// @return WFormButton 实例
  WFormButton build({
    required String name,
    required void Function(String? value, ValueChanged<String> didChange) onTap,
    Widget Function(String value)? selectedWidgetBuilder,
    String? initialValue,
  }) {
    return WFormButton(
      config: this,
      name: name,
      onTap: onTap,
      selectedWidgetBuilder: selectedWidgetBuilder,
      initialValue: initialValue,
    );
  }
}

/// 内部 FormBuilder 按钮组件
class _WFormBuilderButton<T> extends FormBuilderField<T> {
  /// 提示 widget
  final Widget? hintWidget;

  /// 选中值的 widget 构建器
  final Widget Function(T value)? selectedWidgetBuilder;

  /// 点击回调函数
  final void Function(T? value, ValueChanged<T> didChange) onTap;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param name 字段名称
  /// @param validator 验证器
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param valueTransformer 值转换器
  /// @param enabled 是否启用
  /// @param onSaved 保存回调
  /// @param autovalidateMode 自动验证模式
  /// @param onReset 重置回调
  /// @param focusNode 焦点节点
  /// @param restorationId 恢复 ID
  /// @param selectedWidgetBuilder 选中值的 widget 构建器
  /// @param onTap 点击回调函数
  /// @param hintWidget 提示 widget
  _WFormBuilderButton({
    super.key,
    required super.name,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.valueTransformer,
    super.enabled,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.onReset,
    super.focusNode,
    super.restorationId,
    this.selectedWidgetBuilder,
    required this.onTap,
    this.hintWidget,
  }) : super(
         builder: (FormFieldState<T?> field) {
           // 获取状态
           final state = field as _WFormBuilderButtonState;

           return GestureDetector(
             behavior: HitTestBehavior.opaque,
             onTap: () {
               if (state.enabled == false) {
                 return;
               }
               onTap.call(state.value, (a) {
                 state.setValue(a);
                 state.didChange(state.value);
               });
             },
             child: Builder(
               builder: (_) {
                 if (state.value == null) {
                   return hintWidget ?? Container();
                 }
                 return (selectedWidgetBuilder?.call(state.value!) ?? Container());
               },
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<_WFormBuilderButton<T>, T> createState() => _WFormBuilderButtonState();
}

/// _WFormBuilderButton 的状态类
class _WFormBuilderButtonState<T> extends FormBuilderFieldState<_WFormBuilderButton<T>, T> {}
