import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

/// 徽章组件，用于显示角标或标记
class WBadge extends StatelessWidget {
  /// 徽章配置
  final WBadgeConfig? config;

  /// 徽章内容
  final Widget? badgeContent;

  /// 子组件
  final Widget? child;

  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [config]：徽章配置
  /// - [badgeContent]：徽章内容
  /// - [child]：子组件
  WBadge({
    super.key,
    this.config,
    this.badgeContent,
    this.child,
  }) : assert(
         config == null || !config.isShown || badgeContent != null,
         'WBadge: 显示徽章时 badgeContent 不能为空',
       );

  @override
  Widget build(BuildContext context) {
    final config = this.config ?? const WBadgeConfig();
    assert(
      !config.showBadge || badgeContent != null,
      'WBadge: 显示徽章时 badgeContent 不能为空',
    );
    final showBadge = config.showBadge && badgeContent != null;

    return badges.Badge(
      showBadge: showBadge,
      position: config.position,
      badgeStyle:
          config.badgeStyle ??
          const badges.BadgeStyle(
            padding: EdgeInsets.zero,
            borderSide: BorderSide(color: Colors.transparent, width: 0),
            badgeColor: Colors.transparent,
          ),
      badgeContent: badgeContent,
      badgeAnimation: const badges.BadgeAnimation.fade(
        animationDuration: Duration(milliseconds: 0),
      ),
      child: child,
    );
  }
}

/// 徽章配置类（不可变；用构造 / [copyWith] 派生）
@immutable
class WBadgeConfig {
  /// 创建配置
  const WBadgeConfig({
    this.position,
    this.showBadge = true,
    this.badgeStyle,
  });

  /// 徽章位置
  final badges.BadgePosition? position;

  /// 是否显示徽章
  final bool showBadge;

  /// 自定义徽章样式；为 null 时使用透明样式，由 badgeContent 自带视觉
  final badges.BadgeStyle? badgeStyle;

  /// 右上角位置（常用场景的便捷构造）
  factory WBadgeConfig.topRight({double? top, double? end}) {
    return WBadgeConfig(
      position: badges.BadgePosition.topEnd(top: top ?? 0, end: end ?? 0),
    );
  }

  /// 居中位置
  factory WBadgeConfig.center() {
    return WBadgeConfig(position: badges.BadgePosition.center());
  }

  /// 是否显示徽章
  bool get isShown => showBadge;

  /// 创建副本并选择性更新（可空字段传 null 表示清空）
  WBadgeConfig copyWith({
    Object? position = _unset,
    bool? showBadge,
    Object? badgeStyle = _unset,
  }) {
    return WBadgeConfig(
      position: identical(position, _unset) ? this.position : position as badges.BadgePosition?,
      showBadge: showBadge ?? this.showBadge,
      badgeStyle: identical(badgeStyle, _unset)
          ? this.badgeStyle
          : badgeStyle as badges.BadgeStyle?,
    );
  }
}

const Object _unset = Object();
