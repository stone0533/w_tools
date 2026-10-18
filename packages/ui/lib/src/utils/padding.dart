import 'package:flutter/material.dart';

/// Padding 工具类，提供静态工厂方法
class WPadding {
  /// 创建只包含水平 padding 的 Padding
  static Padding horizontal(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
  }

  /// 创建只包含垂直 padding 的 Padding
  static Padding vertical(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: child,
    );
  }

  /// 创建对称的 padding
  static Padding symmetric({double? horizontal, double? vertical, required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal ?? 0, vertical: vertical ?? 0),
      child: child,
    );
  }

  /// 创建只包含左侧 padding 的 Padding
  static Padding left(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(left: padding),
      child: child,
    );
  }

  /// 创建只包含右侧 padding 的 Padding
  static Padding right(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: child,
    );
  }

  /// 创建只包含顶部 padding 的 Padding
  static Padding top(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: child,
    );
  }

  /// 创建只包含底部 padding 的 Padding
  static Padding bottom(double padding, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: child,
    );
  }
}
