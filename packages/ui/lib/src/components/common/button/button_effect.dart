part of 'button.dart';

Widget _buildButtonOverlay(
  Widget child,
  Color color,
  BorderRadiusGeometry? borderRadius,
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
  _WButtonState state,
  WButtonStyle style,
  bool pressed,
  Widget child,
) {
  switch (style.effect) {
    case WButtonEffectType.none:
      return child;
    case WButtonEffectType.opacity:
      return AnimatedOpacity(
        opacity: pressed ? style.pressedOpacity.clamp(0.0, 1.0) : 1.0,
        duration: style.animationDuration,
        curve: style.curve,
        child: child,
      );
    case WButtonEffectType.scale:
      return AnimatedScale(
        scale: pressed ? style.pressedScale.clamp(0.1, 1.0) : 1.0,
        duration: style.animationDuration,
        curve: style.curve,
        child: child,
      );
    case WButtonEffectType.shake:
      return AnimatedBuilder(
        animation: state._shakeFor(style),
        builder: (context, child) {
          final offset = sin(state._shakeAnimation!.value * 2 * pi * 3) * 4;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: child,
      );
  }
}
