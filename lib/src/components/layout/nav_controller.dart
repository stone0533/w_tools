import 'package:flutter/material.dart';

class WNavController extends ChangeNotifier {
  int _currentIndex;
  int _previousIndex;
  final int length;
  final TickerProvider vsync;
  late AnimationController _animationController;
  Animation<double>? _animation;

  int get currentIndex => _currentIndex;
  int get previousIndex => _previousIndex;
  Animation<double> get animation => _animation!;
  bool get indexIsChanging => _animationController.isAnimating;
  double get offset => _animationController.value;

  WNavController({
    int initialIndex = 0,
    required this.length,
    required this.vsync,
  }) : _currentIndex = initialIndex,
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

  void setIndex(int index) {
    currentIndex = index;
  }

  Future<void> animateTo(int index, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) async {
    if (index < 0 || index >= length) {
      return;
    }

    _previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    final AnimationController controller = _animationController;
    controller.duration = duration ?? kTabScrollDuration;
    await controller.forward(from: 0.0);
    await controller.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
