import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../../w.dart';

/// 表单单选按钮组组件
class WFormRadioGroup<T> extends FormBuilderField<T> {
  /// 单选按钮组配置
  final WFormRadioGroupConfig config;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 自定义文本构建器
  final Widget Function(BuildContext, T, String, bool)? itemBuilder;

  /// 自定义子项构建器
  final Widget Function(BuildContext, T, String, bool)? itemChildBuilder;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 单选按钮组配置
  /// @param name 字段名称
  /// @param items 选项映射
  /// @param itemBuilder 自定义文本构建器
  /// @param itemChildBuilder 自定义子项构建器
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  WFormRadioGroup({
    super.key,
    required this.config,
    required super.name,
    required this.items,
    this.itemBuilder,
    this.itemChildBuilder,
    super.initialValue,
    super.onChanged,
  }) : super(
         enabled: config._enabled,
         builder: (FormFieldState<T?> field) {
           // 获取状态
           final state = field as _WFormRadioGroupState;

           /// 点击处理函数
           void click(T v) {
             if (!state.enabled) {
               return;
             }
             state.setValue(v);
             state.didChange(v);
           }

           return Padding(
             padding: config._padding ?? EdgeInsets.zero,
             child: Wrap(
               runSpacing: config._lineSpacing ?? 0,
               children: items.entries.map((element) {
                 final isSelected = state.value == element.key;

                 // 自定义子项构建器
                 Widget? child = itemChildBuilder != null
                     ? itemChildBuilder(field.context, element.key, element.value, isSelected)
                     : null;

                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Row(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         GestureDetector(
                           behavior: HitTestBehavior.opaque,
                           onTap: () => click(element.key),
                           child: Transform(
                             transform: Matrix4.translationValues(0, config._iconYOffset ?? 0, 0),
                             child: Builder(
                               builder: (_) {
                                 if (isSelected) {
                                   return config._selectedIcon ??
                                       WConfig.radioSelectedIcon;
                                 }
                                 return config._unselectedIcon ??
                                     WConfig.radioUnselectedIcon;
                               },
                             ),
                           ),
                         ),
                         SizedBox(width: config._spacing ?? 0),
                         Expanded(
                           child: GestureDetector(
                             behavior: HitTestBehavior.opaque,
                             onTap: () => click(element.key),
                             child: itemBuilder != null
                                 ? itemBuilder(
                                     field.context,
                                     element.key,
                                     element.value,
                                     isSelected,
                                   )
                                 : Text(
                                     element.value,
                                     style: config._style,
                                     strutStyle: StrutStyle(
                                       fontFamily: config._style?.fontFamily,
                                       fontSize: config._style?.fontSize,
                                       height: config._style?.height,
                                       forceStrutHeight: true,
                                     ),
                                   ),
                           ),
                         ),
                       ],
                     ),
                     if (child != null) child,
                   ],
                 );
               }).toList(),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormRadioGroup<T>, T> createState() => _WFormRadioGroupState();
}

/// WFormRadioGroup 的状态类
class _WFormRadioGroupState<T> extends FormBuilderFieldState<WFormRadioGroup<T>, T> {}

/// 单选按钮组配置类，定义单选按钮组的样式和行为
class WFormRadioGroupConfig {
  /// 未选中状态的图标
  Widget? _unselectedIcon;

  /// 选中状态的图标
  Widget? _selectedIcon;

  /// 图标与文本之间的间距
  double? _spacing;

  /// 行间距
  double? _lineSpacing;

  /// 图标 Y 轴偏移
  double? _iconYOffset;

  /// 是否启用
  bool _enabled = true;

  /// 内容内边距
  EdgeInsetsGeometry? _padding;

  /// 文本样式
  TextStyle? _style;

  /// 未选中状态图标 setter
  set unselectedIcon(Widget value) {
    _unselectedIcon = value;
  }

  /// 选中状态图标 setter
  set selectedIcon(Widget value) {
    _selectedIcon = value;
  }

  /// 间距 setter
  set spacing(double value) {
    _spacing = value;
  }

  /// 图标 Y 轴偏移 setter
  set iconYOffset(double value) {
    _iconYOffset = value;
  }

  /// 是否启用 setter
  set enabled(bool value) {
    _enabled = value;
  }

  /// 行间距 setter
  set lineSpacing(double value) {
    _lineSpacing = value;
  }

  /// 内容内边距 setter
  set padding(EdgeInsetsGeometry? value) {
    _padding = value;
  }

  /// 文本样式 setter
  set style(TextStyle? value) {
    _style = value;
  }

  /// 构建 WFormRadioGroup 组件
  ///
  /// @param T 选项值类型
  /// @param name 字段名称
  /// @param items 选项映射，键为值，值为显示文本
  /// @param itemBuilder 自定义文本构建器
  /// @param itemChildBuilder 自定义子项构建器
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @return WFormRadioGroup 实例
  WFormRadioGroup<T> build<T>({
    required String name,
    required Map<T, String> items,
    Widget Function(BuildContext, T, String, bool)? itemBuilder,
    Widget Function(BuildContext, T, String, bool)? itemChildBuilder,
    T? initialValue,
    ValueChanged<T?>? onChanged,
  }) {
    return WFormRadioGroup<T>(
      config: this,
      name: name,
      items: items,
      itemBuilder: itemBuilder,
      itemChildBuilder: itemChildBuilder,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}
