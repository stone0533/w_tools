import 'package:flutter/material.dart';

/// 表单图标集合（不可变）。
///
/// 通过 `WForm(icons: ...)` 或 `WFormTheme(icons: ...)` 统一替换；单个字段的
/// 显式图标参数仍优先。旧 `WFormDefaults` 已在 4.0 删除。
@immutable
class WFormIcons {
  const WFormIcons({
    this.dropdown = const Icon(Icons.keyboard_arrow_down),
    this.radioUnselected = const Icon(Icons.radio_button_off),
    this.radioSelected = const Icon(Icons.radio_button_checked),
    this.checkboxUnselected = const Icon(Icons.check_box_outline_blank),
    this.checkboxSelected = const Icon(Icons.check_box),
    this.obscureText = const Icon(Icons.visibility_off),
    this.obscureTextVisible = const Icon(Icons.visibility),
    this.clear = const Icon(Icons.clear, size: 18),
  });

  /// 包内默认图标
  static const WFormIcons defaults = WFormIcons();

  /// 下拉箭头
  final Widget dropdown;

  /// 单选框未选中
  final Widget radioUnselected;

  /// 单选框选中
  final Widget radioSelected;

  /// 复选框未选中
  final Widget checkboxUnselected;

  /// 复选框选中
  final Widget checkboxSelected;

  /// 密码隐藏
  final Widget obscureText;

  /// 密码可见
  final Widget obscureTextVisible;

  /// 清空按钮
  final Widget clear;

  /// 创建副本
  WFormIcons copyWith({
    Widget? dropdown,
    Widget? radioUnselected,
    Widget? radioSelected,
    Widget? checkboxUnselected,
    Widget? checkboxSelected,
    Widget? obscureText,
    Widget? obscureTextVisible,
    Widget? clear,
  }) {
    return WFormIcons(
      dropdown: dropdown ?? this.dropdown,
      radioUnselected: radioUnselected ?? this.radioUnselected,
      radioSelected: radioSelected ?? this.radioSelected,
      checkboxUnselected: checkboxUnselected ?? this.checkboxUnselected,
      checkboxSelected: checkboxSelected ?? this.checkboxSelected,
      obscureText: obscureText ?? this.obscureText,
      obscureTextVisible: obscureTextVisible ?? this.obscureTextVisible,
      clear: clear ?? this.clear,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WFormIcons &&
      other.dropdown == dropdown &&
      other.radioUnselected == radioUnselected &&
      other.radioSelected == radioSelected &&
      other.checkboxUnselected == checkboxUnselected &&
      other.checkboxSelected == checkboxSelected &&
      other.obscureText == obscureText &&
      other.obscureTextVisible == obscureTextVisible &&
      other.clear == clear;

  @override
  int get hashCode => Object.hash(
    dropdown,
    radioUnselected,
    radioSelected,
    checkboxUnselected,
    checkboxSelected,
    obscureText,
    obscureTextVisible,
    clear,
  );
}
