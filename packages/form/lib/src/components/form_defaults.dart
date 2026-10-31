import 'package:flutter/material.dart';

/// 表单全局默认值（静态兜底）
///
/// 这些字段是可替换的静态变量，修改后对之后构建的表单组件生效；
/// 若某个组件显式配置了对应项，则优先使用组件自身的配置。
///
/// 需要按页面 / 品牌隔离时，优先使用 `WFormTheme`；本类只作为最终回退。
class WFormDefaults {
  static const _dropdownIcon = Icon(Icons.keyboard_arrow_down);
  static const _radioUnselectedIcon = Icon(Icons.radio_button_off);
  static const _radioSelectedIcon = Icon(Icons.radio_button_checked);
  static const _checkboxUnselectedIcon = Icon(Icons.check_box_outline_blank);
  static const _checkboxSelectedIcon = Icon(Icons.check_box);
  static const _obscureTextIcon = Icon(Icons.visibility_off);
  static const _obscureTextVisibleIcon = Icon(Icons.visibility);
  static const _clearButtonIcon = Icon(Icons.clear, size: 18);

  /// 下拉箭头图标
  static Widget dropdownIcon = _dropdownIcon;

  /// 单选框未选中图标
  static Widget radioUnselectedIcon = _radioUnselectedIcon;

  /// 单选框选中图标
  static Widget radioSelectedIcon = _radioSelectedIcon;

  /// 复选框未选中图标
  static Widget checkboxUnselectedIcon = _checkboxUnselectedIcon;

  /// 复选框选中图标
  static Widget checkboxSelectedIcon = _checkboxSelectedIcon;

  /// 密码隐藏图标
  static Widget obscureTextIcon = _obscureTextIcon;

  /// 密码可见图标
  static Widget obscureTextVisibleIcon = _obscureTextVisibleIcon;

  /// 清空按钮图标
  static Widget clearButtonIcon = _clearButtonIcon;

  /// 恢复全部默认图标（测试 / 多品牌切换后使用）
  static void reset() {
    dropdownIcon = _dropdownIcon;
    radioUnselectedIcon = _radioUnselectedIcon;
    radioSelectedIcon = _radioSelectedIcon;
    checkboxUnselectedIcon = _checkboxUnselectedIcon;
    checkboxSelectedIcon = _checkboxSelectedIcon;
    obscureTextIcon = _obscureTextIcon;
    obscureTextVisibleIcon = _obscureTextVisibleIcon;
    clearButtonIcon = _clearButtonIcon;
  }

  WFormDefaults._();
}
