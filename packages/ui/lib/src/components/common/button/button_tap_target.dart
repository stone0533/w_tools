part of 'button.dart';

Widget _buildButtonTapTarget(Widget child, WButtonStyle style) {
  final horizontal = max(0.0, style.tapTargetSize - style.minWidth);
  final vertical = max(0.0, style.tapTargetSize - style.minHeight);
  if (horizontal == 0 && vertical == 0) return child;
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontal / 2,
      vertical: vertical / 2,
    ),
    child: child,
  );
}
