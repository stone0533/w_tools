import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 用户体验优化工具类
class WUX {
  /// 单例实例
  static final WUX _instance = WUX._internal();

  /// 构造函数
  factory WUX() {
    return _instance;
  }

  /// 内部构造函数
  WUX._internal();

  /// 防抖函数
  ///
  /// @param function 要执行的函数
  /// @param duration 防抖时间（毫秒）
  /// @return 防抖后的函数
  Function() debounce(Function() function, {int duration = 300}) {
    Timer? timer;
    return () {
      if (timer != null) {
        timer!.cancel();
      }
      timer = Timer(Duration(milliseconds: duration), function);
    };
  }

  /// 节流函数
  ///
  /// @param function 要执行的函数
  /// @param duration 节流时间（毫秒）
  /// @return 节流后的函数
  Function() throttle(Function() function, {int duration = 300}) {
    bool isExecuting = false;
    return () {
      if (!isExecuting) {
        isExecuting = true;
        function();
        Future.delayed(Duration(milliseconds: duration), () {
          isExecuting = false;
        });
      }
    };
  }

  /// 延迟执行
  ///
  /// @param function 要执行的函数
  /// @param duration 延迟时间（毫秒）
  Future<void> delay(Function() function, {int duration = 0}) async {
    await Future.delayed(Duration(milliseconds: duration));
    function();
  }

  /// 在下一帧执行
  ///
  /// @param function 要执行的函数
  void nextFrame(Function() function) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      function();
    });
  }

  /// 平滑滚动到指定位置
  ///
  /// @param scrollController 滚动控制器
  /// @param offset 目标偏移量
  /// @param duration 动画时长
  Future<void> smoothScrollTo(
    ScrollController scrollController,
    double offset, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await scrollController.animateTo(
      offset,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  /// 平滑滚动到顶部
  ///
  /// @param scrollController 滚动控制器
  /// @param duration 动画时长
  Future<void> smoothScrollToTop(
    ScrollController scrollController, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await smoothScrollTo(scrollController, 0, duration: duration);
  }

  /// 平滑滚动到底部
  ///
  /// @param scrollController 滚动控制器
  /// @param duration 动画时长
  Future<void> smoothScrollToBottom(
    ScrollController scrollController, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await smoothScrollTo(
      scrollController,
      scrollController.position.maxScrollExtent,
      duration: duration,
    );
  }

  /// 动画曲线
  static const Curve defaultCurve = Curves.easeInOut;

  /// 动画时长
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// 快速动画时长
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// 慢速动画时长
  static const Duration slowDuration = Duration(milliseconds: 500);
}
