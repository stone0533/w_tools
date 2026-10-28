part of 'button.dart';

Widget _buildButtonLabel(_WButtonState state, WButtonStyle style) {
  final widget = state.widget;
  final label = widget.label;
  final icon = widget.icon;
  if (label != null && icon != null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: style.iconSize),
        SizedBox(width: style.gap),
        WText(text: label, config: style.textStyle),
      ],
    );
  }
  if (icon != null) return Icon(icon, size: style.iconSize);
  if (label != null) return WText(text: label, config: style.textStyle);
  return const SizedBox.shrink();
}

Widget _buildButtonLoading(
  _WButtonState state,
  BuildContext context,
  WButtonStyle style,
) {
  final child = state.widget.loadingBuilder?.call(context) ??
      const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
  return Semantics(
    label: style.loadingLabel,
    container: true,
    child: child,
  );
}

Widget _buildButtonContent(
  _WButtonState state,
  BuildContext context,
  WButtonStyle style,
  Widget child,
) {
  if (!state.widget.loading) return child;

  // loading 时保留 child 占位，避免按钮尺寸跳动。
  return Stack(
    alignment: Alignment.center,
    children: [
      ExcludeSemantics(
        child: Opacity(opacity: 0, child: child),
      ),
      _buildButtonLoading(state, context, style),
    ],
  );
}
