import 'package:flutter/material.dart';

/// 底部导航栏控制器
///
/// 维护当前/上一个索引，并提供切换过渡动画；由 `WNavBar` 使用。
/// 调用方在使用完毕后需调用 [dispose] 释放内部动画资源。
class WNavController extends ChangeNotifier {
  int _currentIndex;
  int _previousIndex;

  /// 导航项数量（构造后不可变）
  final int length;

  /// 创建内部动画控制器所需的 vsync
  final TickerProvider vsync;
  late AnimationController _animationController;
  Animation<double>? _animation;
  int _transitionToken = 0;
  bool _disposed = false;

  /// 当前选中索引
  int get currentIndex => _currentIndex;

  /// 上一次的选中索引
  int get previousIndex => _previousIndex;

  /// 切换过渡动画
  Animation<double> get animation => _animation!;

  /// 是否正在播放切换动画
  bool get indexIsChanging => _animationController.isAnimating;

  /// 动画当前进度（0.0-1.0）
  double get offset => _animationController.value;

  WNavController({
    int initialIndex = 0,
    required this.length,
    required this.vsync,
  })  : assert(length >= 0),
        assert(length == 0 || (initialIndex >= 0 && initialIndex < length)),
        _currentIndex = initialIndex,
        _previousIndex = initialIndex {
    _animationController = AnimationController(
      duration: kTabScrollDuration,
      vsync: vsync,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  set currentIndex(int value) {
    if (_currentIndex != value && value >= 0 && value < length) {
      _previousIndex = _currentIndex;
      _currentIndex = value;
      notifyListeners();
    }
  }

  Future<void> animateTo(
    int index, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) async {
    if (_disposed || index < 0 || index >= length || index == _currentIndex) {
      return;
    }

    final token = ++_transitionToken;
    _previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    final AnimationController controller = _animationController;
    controller.duration = duration ?? kTabScrollDuration;
    // 应用调用方传入的曲线
    _animation = CurvedAnimation(parent: controller, curve: curve);
    try {
      await controller.forward(from: 0.0).orCancel;
      if (_disposed || token != _transitionToken) return;
      await controller.reverse().orCancel;
    } on TickerCanceled {
      // controller 在过渡期间被释放
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _transitionToken++;
    _animationController.dispose();
    super.dispose();
  }
}
