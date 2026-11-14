import 'package:flutter/material.dart';

/// 声明式通知监听器。
///
/// [onNotification] 与 [onNotificationPercentage] 可同时生效：先计算滚动百分比，
/// 再把通知交给 [onNotification] 决定是否继续传递（返回 true 表示已处理、阻止冒泡）。
class WNotificationListener<T extends Notification> extends StatelessWidget {
  const WNotificationListener({
    super.key,
    required this.child,
    this.onNotification,
    this.onNotificationPercentage,
  });

  final Widget child;
  final bool Function(T notification)? onNotification;
  final void Function(double percentage)? onNotificationPercentage;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<T>(
      onNotification: (notification) {
        _notifyScrollPercentage(notification, onNotificationPercentage);
        return onNotification?.call(notification) ?? false;
      },
      child: child,
    );
  }
}

/// 计算并回调顶层滚动百分比。
void _notifyScrollPercentage(
  Notification notification,
  void Function(double percentage)? callback,
) {
  if (callback == null) return;
  if (notification is! ScrollUpdateNotification || notification.depth != 0) return;

  final metrics = notification.metrics;
  if (metrics.maxScrollExtent <= 0) {
    callback(0.0);
    return;
  }
  callback((metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0));
}
