import 'package:flutter/material.dart';

/// 底部导航的默认项描述。
///
/// 传给 `WNavBar(destinations: [...])` 时由组件渲染默认的图标 + 文字；
/// 需要完全自定义时继续用 `WNavBar.itemBuilder`。
@immutable
class WNavDestination {
  const WNavDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.semanticLabel,
  });

  /// 未选中时的图标
  final IconData icon;

  /// 选中时的图标；null 时继续用 [icon]
  final IconData? selectedIcon;

  /// 文案
  final String label;

  /// 读屏标签；null 时使用 [label]
  final String? semanticLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WNavDestination &&
          other.icon == icon &&
          other.selectedIcon == selectedIcon &&
          other.label == label &&
          other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(icon, selectedIcon, label, semanticLabel);
}
