import 'package:flutter/foundation.dart';

/// 底部导航栏控制器
///
/// 只维护当前索引并通知监听者；选中态的视觉过渡由页面自己决定，
/// 因此不需要 `vsync`，也不持有动画资源。
class WNavController extends ChangeNotifier {
  int _currentIndex;

  /// 导航项数量（构造后不可变）
  final int length;

  /// 当前选中索引
  int get currentIndex => _currentIndex;

  WNavController({
    int initialIndex = 0,
    required this.length,
  }) : assert(length >= 0),
       assert(length == 0 || (initialIndex >= 0 && initialIndex < length)),
       _currentIndex = initialIndex;

  set currentIndex(int value) {
    if (_currentIndex == value || value < 0 || value >= length) return;
    _currentIndex = value;
    notifyListeners();
  }
}
