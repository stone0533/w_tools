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
  WButtonStyle style,
  bool pressed,
  Widget child,
) {
  switch (style.motion.effect) {
    case WButtonEffectType.none:
      return child;
    case WButtonEffectType.opacity:
      return AnimatedOpacity(
        opacity: pressed ? style.motion.pressedOpacity.clamp(0.0, 1.0) : 1.0,
        duration: style.motion.duration,
        curve: style.motion.curve,
        child: child,
      );
    case WButtonEffectType.scale:
      return AnimatedScale(
        scale: pressed ? style.motion.pressedScale.clamp(0.1, 1.0) : 1.0,
        duration: style.motion.duration,
        curve: style.motion.curve,
        child: child,
      );
  }
}
