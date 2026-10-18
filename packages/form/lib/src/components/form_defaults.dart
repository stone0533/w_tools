import 'package:flutter/material.dart';

/// 表单全局默认值
///
/// 这些字段是可替换的静态变量，修改后对之后构建的表单组件生效；
/// 若某个组件显式配置了对应项，则优先使用组件自身的配置。
class WFormDefaults {
  /// 下拉箭头图标
  static Widget dropdownIcon = const Icon(Icons.keyboard_arrow_down);

  /// 单选框未选中图标
  static Widget radioUnselectedIcon = const Icon(Icons.radio_button_off);

  /// 单选框选中图标
  static Widget radioSelectedIcon = const Icon(Icons.radio_button_checked);

  /// 复选框未选中图标
  static Widget checkboxUnselectedIcon = const Icon(Icons.check_box_outline_blank);

  /// 复选框选中图标
  static Widget checkboxSelectedIcon = const Icon(Icons.check_box);

  /// 密码隐藏图标
  static Widget obscureTextIcon = const Icon(Icons.visibility_off);

  /// 密码可见图标
  static Widget obscureTextVisibleIcon = const Icon(Icons.visibility);

  /// 清空按钮图标
  static Widget clearButtonIcon = const Icon(Icons.clear, size: 18);

  WFormDefaults._();
}
