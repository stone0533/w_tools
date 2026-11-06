import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 在 build / layout / paint 阶段只更新 value，监听通知延后到帧结束。
///
/// `WImage` 的 frameBuilder / loadingBuilder / errorBuilder 会在 build 期间更新
/// 加载状态；如果外部监听器（例如 ValueListenableBuilder）同步 setState，会触发
/// “setState() called during build”。加载器与 controller 都使用这个 notifier。
class WImageDeferredValueNotifier<T> extends ValueNotifier<T> {
  WImageDeferredValueNotifier(super.value);

  bool _notificationScheduled = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } on FlutterError {
      // 纯 Dart 测试里可能还没有初始化 Binding；此时按普通 ValueNotifier 处理。
      binding = null;
    }
    if (binding != null && binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      binding.addPostFrameCallback((_) {
        _notificationScheduled = false;
        if (_disposed) return;
        super.notifyListeners();
      });
      return;
    }
    super.notifyListeners();
  }
}
