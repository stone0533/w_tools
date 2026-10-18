import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

/// 徽章组件，用于显示角标或标记
class WBadge extends StatelessWidget {
  /// 徽章配置
  final WBadgeConfig config;

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
  const WBadge({
    super.key,
    required this.config,
    this.badgeContent,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
      showBadge: config._showBadge,
      position: config._position,
      badgeStyle: const badges.BadgeStyle(
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

/// 徽章配置类，用于配置徽章的位置和显示状态
class WBadgeConfig {
  /// 徽章位置
  badges.BadgePosition? _position;

  /// 是否显示徽章
  bool _showBadge = true;

  /// 设置徽章的自定义位置
  ///
  /// - [start]：左侧距离
  /// - [end]：右侧距离
  /// - [top]：顶部距离
  /// - [bottom]：底部距离
  /// - [isCenter]：是否居中
  /// 返回：WBadgeConfig 实例，用于链式调用
  WBadgeConfig position({
    double? start,
    double? end,
    double? top,
    double? bottom,
    bool isCenter = false,
  }) {
    _position = badges.BadgePosition.custom(
      start: start,
      end: end,
      top: top,
      bottom: bottom,
      isCenter: isCenter,
    );
    return this;
  }

  /// 设置徽章位置为右上角
  ///
  /// - [top]：顶部距离
  /// - [right]：右侧距离
  /// 返回：WBadgeConfig 实例，用于链式调用
  WBadgeConfig positionTopRight(double top, double right) {
    _position = badges.BadgePosition.topEnd(top: top, end: right);
    return this;
  }

  /// 设置徽章位置为中心
  ///
  /// 返回：WBadgeConfig 实例，用于链式调用
  WBadgeConfig positionCenter() {
    _position = badges.BadgePosition.center();
    return this;
  }

  /// 隐藏徽章
  ///
  /// 返回：WBadgeConfig 实例，用于链式调用
  WBadgeConfig hideBadge() {
    _showBadge = false;
    return this;
  }
}
