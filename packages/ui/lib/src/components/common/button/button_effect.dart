part of 'button.dart';

Widget _buildButtonOverlay(
  Widget child,
  Color color,
  BorderRadius? borderRadius,
) {
  Widget overlay = ColoredBox(color: color);
  if (borderRadius != null) {
    overlay = ClipRRect(borderRadius: borderRadius, child: overlay);
  }
  return Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(child: overlay),
      ),
    ],
  );
}

Widget _buildButtonVisual(
  WButtonMotion motion,
  bool pressed,
  Widget child,
) {
  switch (motion.effect) {
    case WPressEffect.none:
      return child;
    case WPressEffect.opacity:
      return AnimatedOpacity(
        opacity: pressed ? motion.pressedOpacity.clamp(0.0, 1.0) : 1.0,
        duration: motion.duration,
        curve: motion.curve,
        child: child,
      );
    case WPressEffect.scale:
      return AnimatedScale(
        scale: pressed ? motion.pressedScale.clamp(0.1, 1.0) : 1.0,
        duration: motion.duration,
        curve: motion.curve,
        child: child,
      );
  }
}
