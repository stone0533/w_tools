import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:w_tools/src/config.dart';

/// 单个复选框字段组件
class WFormCheckbox extends FormBuilderField<bool> {
  /// 复选框配置
  final WFormCheckboxConfig config;

  /// 标题 widget
  final Widget? title;

  /// 创建单个复选框字段
  ///
  /// @param key 组件键
  /// @param config 复选框配置
  /// @param name 字段名称
  /// @param title 标题 widget
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  WFormCheckbox({
    //From Super
    super.key,
    required this.config,
    required super.name,
    required this.title,
    bool super.initialValue = false,
    super.onChanged,
    //FormFieldValidator<bool>? validator,
    //ValueTransformer<bool?>? valueTransformer,
    //FormFieldSetter<bool?>? onSaved,
    //AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    //VoidCallback? onReset,
    //FocusNode? focusNode,
  }) : super(
         enabled: config._enabled,
         //validator: validator,
         //valueTransformer: valueTransformer,
         //autovalidateMode: autovalidateMode,
         //onSaved: onSaved,
         //onReset: onReset,
         //focusNode: focusNode,
         builder: (FormFieldState<bool?> field) {
           // 获取状态
           final state = field as _WFormCheckboxState;

           /// 点击处理函数
           void click() {
             if (state.enabled == false) {
               return;
             }
             if (state.value != null) {
               var v = state.value == false;
               state.setValue(v);
               state.didChange(v);
             }
           }

           return Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               GestureDetector(
                 behavior: HitTestBehavior.opaque,
                 onTap: click,
                 child: Transform(
                   transform: Matrix4.translationValues(0, config._iconYOffset ?? 0, 0),
                   child: Builder(
                     builder: (_) {
                       if (state.enabled == false && config._disableIcon != null) {
                         return config._disableIcon!;
                       }
                       if (state.value == true) {
                         return config._selectedIcon ?? WConfig.instance.checkboxSelectedIcon;
                       }
                       return config._unselectedIcon ?? WConfig.instance.checkboxUnselectedIcon;
                     },
                   ),
                 ),
               ),
               SizedBox(width: config._spacing ?? 0),
               Expanded(
                 child: GestureDetector(
                   behavior: HitTestBehavior.opaque,
                   onTap: click,
                   child: title,
                 ),
               ),
             ],
           );
         },
       );

  @override
  FormBuilderFieldState<WFormCheckbox, bool> createState() => _WFormCheckboxState();
}

/// WFormCheckbox 的状态类
class _WFormCheckboxState extends FormBuilderFieldState<WFormCheckbox, bool> {}

/// 复选框配置类，定义复选框的样式和行为
class WFormCheckboxConfig {
  /// 未选中状态的图标
  Widget? _unselectedIcon;

  /// 选中状态的图标
  Widget? _selectedIcon;

  /// 禁用状态的图标
  Widget? _disableIcon;

  /// 图标与标题之间的间距
  double? _spacing;

  /// 图标 Y 轴偏移
  double? _iconYOffset;

  /// 是否启用
  bool _enabled = true;

  /// 禁用状态图标 setter
  set disableIcon(Widget value) {
    _disableIcon = value;
  }

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

  /// 构建 WFormCheckbox 组件
  ///
  /// @param name 字段名称
  /// @param title 标题 widget
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @return WFormCheckbox 实例
  WFormCheckbox build({
    required String name,
    required Widget title,
    bool initialValue = false,
    ValueChanged<bool?>? onChanged,
  }) {
    return WFormCheckbox(
      config: this,
      name: name,
      title: title,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}
