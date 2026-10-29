part of 'button.dart';

TextStyle? _buttonLabelStyle(WButtonStyle style) {
  final base = style.textStyle;
  if (style.foregroundColor == null) return base;
  return (base ?? const TextStyle()).copyWith(color: style.foregroundColor);
}

Widget _buildButtonLabel(_WButtonState state, WButtonStyle style) {
  final widget = state.widget;
  final label = widget.label;
  final icon = widget.icon;
  final textStyle = _buttonLabelStyle(style);
  final iconColor = style.foregroundColor;
  if (label != null && icon != null) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: style.iconSize, color: iconColor),
        SizedBox(width: style.gap),
        Text(label, style: textStyle),
      ],
    );
  }
  if (icon != null) {
    return Icon(icon, size: style.iconSize, color: iconColor);
  }
  if (label != null) return Text(label, style: textStyle);
  return const SizedBox.shrink();
}

Widget _buildButtonContentWidget(
  _WButtonState state,
  BuildContext context,
  WButtonStyle style,
) {
  final builder = state.widget.contentBuilder;
  if (builder != null) return builder(context, style);
  final content = state.widget.content;
  if (content != null) return content;
  return _buildButtonLabel(state, style);
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
    label: style.semantics.loadingLabel,
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
