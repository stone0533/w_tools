import 'package:flutter/material.dart';

/// 通知监听器构建器，用于创建和配置 NotificationListener 组件
///
/// 使用构建器模式，支持链式调用，可配置通知回调和滚动百分比回调
/// 泛型参数 T 用于指定监听的通知类型，默认为 Notification
class WNotificationListener<T extends Notification> {
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
  /// @param child 子组件，必需
  WNotificationListener({required this.child});

  /// 构建 NotificationListener 组件
  ///
  /// @return 配置完成的 NotificationListener 组件
  NotificationListener<T> build() {
    return NotificationListener<T>(
      onNotification: _onNotification ?? _defaultNotificationHandler,
      child: child,
    );
  }

  /// 默认通知处理函数
  ///
  /// 处理常见的滚动通知，包括滚动开始、更新、结束、过度滚动和用户滚动事件
  /// 当设置了滚动百分比回调时，会在滚动更新时计算并触发回调
  ///
  /// @param notification 通知对象
  /// @return 是否阻止通知传递，返回 _preventNotificationPropagation 的值
  bool _defaultNotificationHandler(T notification) {
    if (notification is ScrollStartNotification) {
      // 处理滚动开始事件
      return _preventNotificationPropagation;
    } else if (notification is ScrollUpdateNotification) {
      if (notification.depth == 0) {
        // 计算滚动百分比
        double percentage = notification.metrics.pixels / notification.metrics.maxScrollExtent;
        // 确保百分比在 0.0 到 1.0 之间
        percentage = percentage.clamp(0.0, 1.0);
        // 触发滚动百分比回调
        _onNotificationPercentage?.call(percentage);
      }
      // 处理滚动更新事件
      return _preventNotificationPropagation;
    } else if (notification is ScrollEndNotification) {
      // 处理滚动结束事件
      return _preventNotificationPropagation;
    } else if (notification is OverscrollNotification) {
      // 处理过度滚动事件
      return _preventNotificationPropagation;
    } else if (notification is UserScrollNotification) {
      // 处理用户滚动事件
      return _preventNotificationPropagation;
    }
    return _preventNotificationPropagation;
  }

  /// 设置通知回调函数
  ///
  /// @param onNotification 通知回调函数，接收通知对象并返回是否阻止通知传递
  /// @return WNotificationListener 实例，用于链式调用
  WNotificationListener<T> onNotification(
    bool Function(T)? onNotification,
  ) {
    _onNotification = onNotification;
    return this;
  }

  /// 设置滚动百分比回调函数
  ///
  /// @param onNotificationPercentage 滚动百分比回调函数，接收滚动百分比值（0.0-1.0）
  /// @return WNotificationListener 实例，用于链式调用
  WNotificationListener<T> onNotificationPercentage(
    void Function(double percentage)? onNotificationPercentage,
  ) {
    _onNotificationPercentage = onNotificationPercentage;
    return this;
  }

  /// 设置是否阻止通知传递
  ///
  /// @param prevent 是否阻止通知传递，默认为 false
  /// @return WNotificationListener 实例，用于链式调用
  WNotificationListener<T> setPreventNotificationPropagation(bool prevent) {
    _preventNotificationPropagation = prevent;
    return this;
  }
}

/// WNotificationListener 的便捷构造函数扩展
///
/// 提供了一种更简洁的方式来创建 WNotificationListener 实例
extension WNotificationListenerExtension on Widget {
  /// 创建 WNotificationListener 实例
  ///
  /// @return WNotificationListener<Notification> 实例，默认监听所有类型的通知
  WNotificationListener<Notification> get notificationListener {
    return WNotificationListener<Notification>(child: this);
  }
}
