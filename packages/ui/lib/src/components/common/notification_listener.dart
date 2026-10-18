import 'package:flutter/material.dart';

/// 通知监听器构建器，用于创建和配置 NotificationListener 组件
///
/// 使用构建器模式，支持链式配置通知回调与滚动百分比回调。
/// 泛型参数 T 指定要监听的通知类型（如 ScrollNotification）。
class WNotificationListenerBuilder<T extends Notification> {
  /// 子组件，将被包裹在 NotificationListener 中
  final Widget child;

  /// 通知回调函数，当接收到通知时触发
  bool Function(T)? _onNotification;

  /// 滚动百分比回调函数，当滚动位置变化时触发
  /// 回调参数为当前滚动百分比，范围为 0.0 到 1.0
  void Function(double percentage)? _onNotificationPercentage;

  /// 是否阻止通知传递，默认值为 false
  /// 当设置为 true 时，通知将不会继续向上传递
  bool _preventNotificationPropagation = false;

  /// 构造函数
  ///
  /// - [child]：子组件，必需
  WNotificationListenerBuilder({required this.child});

  /// 构建 NotificationListener 组件
  ///
  /// [onNotification] 与 [onNotificationPercentage] 可以同时生效：
  /// 先计算滚动百分比，再把通知交给自定义回调决定是否继续传递。
  NotificationListener<T> build() {
    return NotificationListener<T>(
      onNotification: _handleNotification,
      child: child,
    );
  }

  /// 统一处理通知
  bool _handleNotification(T notification) {
    _handleScrollPercentage(notification);
    return _onNotification?.call(notification) ?? _preventNotificationPropagation;
  }

  /// 计算并回调顶层滚动百分比
  void _handleScrollPercentage(T notification) {
    final callback = _onNotificationPercentage;
    if (callback == null) return;
    if (notification is! ScrollUpdateNotification || notification.depth != 0) return;

    final metrics = notification.metrics;
    // 不可滚动（maxScrollExtent == 0）时避免 0/0 产生 NaN
    if (metrics.maxScrollExtent <= 0) {
      callback(0.0);
      return;
    }
    callback((metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0));
  }

  /// 设置通知回调函数
  ///
  /// - [onNotification]：通知回调函数，接收通知对象并返回是否阻止通知传递
  /// 返回：WNotificationListenerBuilder 实例，用于链式调用
  WNotificationListenerBuilder<T> onNotification(
    bool Function(T)? onNotification,
  ) {
    _onNotification = onNotification;
    return this;
  }

  /// 设置滚动百分比回调函数
  ///
  /// - [onNotificationPercentage]：滚动百分比回调函数，接收滚动百分比值（0.0-1.0）
  /// 返回：WNotificationListenerBuilder 实例，用于链式调用
  WNotificationListenerBuilder<T> onNotificationPercentage(
    void Function(double percentage)? onNotificationPercentage,
  ) {
    _onNotificationPercentage = onNotificationPercentage;
    return this;
  }

  /// 设置是否阻止通知传递
  ///
  /// - [prevent]：是否阻止通知传递，默认为 false
  /// 返回：WNotificationListenerBuilder 实例，用于链式调用
  WNotificationListenerBuilder<T> setPreventNotificationPropagation(bool prevent) {
    _preventNotificationPropagation = prevent;
    return this;
  }
}

/// WNotificationListenerBuilder 的便捷构造函数扩展
///
/// 提供了一种更简洁的方式来创建 WNotificationListenerBuilder 实例
extension WNotificationListenerBuilderExtension on Widget {
  /// 创建 WNotificationListenerBuilder 实例
  ///
  /// 返回：WNotificationListenerBuilder<Notification> 实例，默认监听所有类型的通知
  WNotificationListenerBuilder<Notification> get notificationListenerBuilder {
    return WNotificationListenerBuilder<Notification>(child: this);
  }
}
