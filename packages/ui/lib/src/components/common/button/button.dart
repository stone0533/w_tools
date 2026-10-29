import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../layout/container.dart';
import '../text.dart';
import 'button_motion.dart';
import 'button_size.dart';
import 'button_style.dart';
import 'button_styles.dart';

export 'button_motion.dart';
export 'button_semantics.dart';
export 'button_size.dart';
export 'button_style.dart';
export 'button_styles.dart';

part 'button_content.dart';
part 'button_effect.dart';
part 'button_tap_target.dart';

/// 按钮内容构建器。
///
/// [style] 是已经合并 theme、variant、size 后的最终样式。
typedef WButtonContentBuilder = Widget Function(
  BuildContext context,
  WButtonStyle style,
);

/// 真正的按钮组件。
///
/// 支持 label/icon、静态 [content]、需要最终样式的 [contentBuilder]；
/// 保留 button 语义、键盘、loading 和最小点击区域。
class WButton extends StatefulWidget {
  const WButton({
    super.key,
    this.style,
    this.label,
    this.icon,
    this.content,
    this.contentBuilder,
    this.size,
    this.semanticLabel,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.loadingBuilder,
    this.focusNode,
    this.autofocus = false,
  })  : assert(
          content != null || contentBuilder != null || label != null || icon != null,
          'WButton: content / contentBuilder / label / icon 至少提供一个',
        ),
        assert(
          (content == null ? 0 : 1) +
                  (contentBuilder == null ? 0 : 1) +
                  ((label != null || icon != null) ? 1 : 0) ==
              1,
          'WButton: content / contentBuilder / label+icon 只能选择一种',
        );

  final WButtonStyle? style;

  /// 简单内容
  final String? label;
  final IconData? icon;

  /// 静态复杂内容
  final Widget? content;

  /// 需要最终 style 的复杂内容
  final WButtonContentBuilder? contentBuilder;

  /// 尺寸；null 时 variant 构造回退到 medium
  final WButtonSize? size;

  /// 显式无障碍标签；纯图标按钮建议提供
  final String? semanticLabel;

  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  final bool enabled;
  final bool loading;

  /// 加载中占位；默认小号 CircularProgressIndicator
  final WidgetBuilder? loadingBuilder;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<WButton> createState() => _WButtonState();
}

class _WButtonState extends State<WButton> {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  Timer? _pressTimer;
  int _pressToken = 0;
  bool _focused = false;
  bool _hovered = false;
  WButtonStyle? _cachedStyle;
  Object? _cachedStyleKey;

  bool get _interactive => widget.enabled && !widget.loading;

  @override
  void dispose() {
    _pressTimer?.cancel();
    _pressed.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) {
      _setPressed(false);
      _focused = false;
      _hovered = false;
    }
  }

  WButtonStyle _resolveStyle() {
    final key = Object.hash(
      widget.style,
      widget.size,
      widget.semanticLabel,
      widget.label,
      widget.icon,
    );
    if (_cachedStyle != null && _cachedStyleKey == key) return _cachedStyle!;

    final base = widget.style ?? WButtonStyles.primary;
    final semantic = widget.semanticLabel;
    final resolved = semantic == null
        ? base.copy()
        : base.copyWith(
            semantics: base.semantics.copyWith(label: semantic),
          );
    final sized = resolved.applySize(widget.size);
    assert(
      widget.icon == null ||
          widget.label != null ||
          widget.content != null ||
          widget.contentBuilder != null ||
          sized.semantics.label != null,
      'WButton: 纯图标按钮请提供 semanticLabel',
    );
    _cachedStyle = sized;
    _cachedStyleKey = key;
    return sized;
  }

  void _setPressed(bool value) {
    if (_pressed.value == value) return;
    _pressed.value = value;
  }

  void _pulse(WButtonStyle style) {
    final token = ++_pressToken;
    _pressTimer?.cancel();
    _setPressed(true);
    _pressTimer = Timer(style.motion.duration, () {
      if (mounted && token == _pressToken) _setPressed(false);
    });
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  void _activate(WButtonStyle style) {
    if (!_interactive || widget.onTap == null) return;
    _pulse(style);
    _handleTap();
  }

  void _onTapDown(WButtonStyle style, TapDownDetails details) {
    if (!_interactive) return;
    _pressToken++;
    _pressTimer?.cancel();
    _setPressed(true);
  }

  void _onTapUp(TapUpDetails details) {
    if (!_interactive) return;
    _setPressed(false);
  }

  void _onTapCancel() {
    if (!_interactive) return;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();
    style.validate();
    final interactive = _interactive;
    final theme = Theme.of(context);

    final child = _buildButtonContentWidget(this, context, style);
    final container = style.container?.copy();
    final inner = _buildButtonContent(this, context, style, child);
    final padded = container == null && style.padding != null
        ? Padding(padding: style.padding!, child: inner)
        : inner;
    final content = container == null ? padded : WContainer(config: container, child: padded);

    Widget visualChild = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: style.minWidth,
        minHeight: style.minHeight,
      ),
      child: content,
    );

    visualChild = IgnorePointer(ignoring: !interactive, child: visualChild);
    if (!interactive) {
      visualChild = Opacity(
        opacity: style.disabledOpacity.clamp(0.0, 1.0),
        child: visualChild,
      );
    }

    final hoverColor = style.hoverColor ?? theme.hoverColor;
    final focusColor = style.focusColor ?? theme.focusColor;

    Widget buildVisual(bool pressed) {
      var result = _buildButtonVisual(style, pressed, visualChild);
      if (_hovered && interactive) {
        result = _buildButtonOverlay(
          result,
          hoverColor,
          style.overlayBorderRadius,
        );
      }
      if (_focused && interactive) {
        result = _buildButtonOverlay(
          result,
          focusColor,
          style.overlayBorderRadius,
        );
      }
      return result;
    }

    return Semantics(
      button: true,
      enabled: interactive,
      label: style.semantics.label,
      hint: style.semantics.hint,
      onTap: interactive && widget.onTap != null ? () => _activate(style) : null,
      onLongPress: interactive && widget.onLongPress != null ? widget.onLongPress : null,
      child: FocusableActionDetector(
        enabled: interactive,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        mouseCursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate(style);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: interactive ? _handleTap : null,
          onLongPress: interactive ? widget.onLongPress : null,
          onTapDown: interactive ? (details) => _onTapDown(style, details) : null,
          onTapUp: interactive ? _onTapUp : null,
          onTapCancel: interactive ? _onTapCancel : null,
          child: ValueListenableBuilder<bool>(
            valueListenable: _pressed,
            builder: (context, pressed, _) => _buildButtonTapTarget(buildVisual(pressed), style),
          ),
        ),
      ),
    );
  }
}
