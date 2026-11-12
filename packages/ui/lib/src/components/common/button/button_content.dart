part of 'button.dart';

Widget _buildButtonLabel(_WButtonState state, WButtonResolvedStyle style) {
  final widget = state.widget;
  final label = widget.label;
  final icon = widget.icon;
  final textStyle = style.textStyle;
  final iconColor = style.foregroundColor;
  if (label != null && icon != null) {
    // 与独立使用时的 WIconText 保持同一套行盒中点对齐 / RTL 间距；
    // iconSize / gap / textStyle 来自已解析的按钮样式。
    return WIconText(
      icon: icon,
      text: label,
      style: textStyle,
      iconSize: style.iconSize,
      iconColor: iconColor,
      gap: style.gap,
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
  WButtonResolvedStyle style,
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
  WButtonResolvedStyle visual,
) {
  // spinner 必须跟随按钮前景色：默认 CircularProgressIndicator 取
  // colorScheme.primary，在主色填充按钮上会和背景同色、几乎不可见。
  final indicatorColor = visual.foregroundColor ?? visual.textStyle?.color;
  final child =
      state.widget.loadingBuilder?.call(context) ??
      SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: indicatorColor,
        ),
      );
  final loadingLabel = state._semantics.loadingLabel;
  return Semantics(
    label: loadingLabel.isEmpty ? WUiStrings.of(context).loadingLabel : loadingLabel,
    container: true,
    liveRegion: true,
    child: child,
  );
}

Widget _buildButtonContent(
  _WButtonState state,
  BuildContext context,
  WButtonResolvedStyle visual,
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
      _buildButtonLoading(state, context, visual),
    ],
  );
}
