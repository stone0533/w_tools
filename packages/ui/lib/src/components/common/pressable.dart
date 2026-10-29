import 'package:flutter/material.dart';

/// 任意 child 的基础点击效果。
enum WPressEffect {
  /// 无效果
  none,

  /// 按下时透明度降低
  opacity,

  /// 按下时轻微缩小
  scale,
}

/// 给任意 child 添加点击能力的轻量包装。
///
/// 这不是按钮：
/// - 不设置 `Semantics.button`；
/// - 不负责背景、圆角、padding、variant、size、theme；
/// - 不负责 loading、最小点击区域、键盘焦点。
///
/// 需要真正的按钮语义或键盘操作时，用 `WButton`。
/// 需要 `Semantics` 时，可显式包一层 `Semantics(button: true)`。
class WPressable extends StatefulWidget {
  const WPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.effect = WPressEffect.opacity,
    this.pressedOpacity = 0.85,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    this.behavior = HitTestBehavior.opaque,
    this.excludeChildSemanticsWhenDisabled = false,
  })  : assert(
          pressedOpacity >= 0 && pressedOpacity <= 1,
          'pressedOpacity 必须在 0..1',
        ),
        assert(
          pressedScale >= 0.1 && pressedScale <= 1,
          'pressedScale 必须在 0.1..1',
        );

  final Widget child;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final bool enabled;
  final WPressEffect effect;
  final double pressedOpacity;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final HitTestBehavior behavior;

  /// 禁用时是否同时排除 child 的语义。
  ///
  /// 默认 false：保留内容语义；如果 child 内部有交互控件，可开启以彻底禁用。
  final bool excludeChildSemanticsWhenDisabled;

  @override
  State<WPressable> createState() => _WPressableState();
}

class _WPressableState extends State<WPressable> {
  var _pressed = false;

  bool get _actionable => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void didUpdateWidget(WPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_actionable) _setPressed(false);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_actionable) return;
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (!_actionable) return;
    widget.onLongPress?.call();
  }

  void _handleTapDown() {
    if (!_actionable) return;
    _setPressed(true);
  }

  void _handleTapUp() {
    if (!_actionable) return;
    _setPressed(false);
  }

  Widget _effect(Widget child) {
    switch (widget.effect) {
      case WPressEffect.none:
        return child;
      case WPressEffect.opacity:
        return AnimatedOpacity(
          opacity: _pressed ? widget.pressedOpacity.clamp(0.0, 1.0) : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: child,
        );
      case WPressEffect.scale:
        return AnimatedScale(
          scale: _pressed ? widget.pressedScale.clamp(0.1, 1.0) : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.duration.isNegative, 'duration 不能为负');
    if (!widget.enabled) {
      final disabled = IgnorePointer(child: widget.child);
      return widget.excludeChildSemanticsWhenDisabled
          ? ExcludeSemantics(child: disabled)
          : disabled;
    }
    if (!_actionable) {
      return widget.child;
    }

    final content = _effect(widget.child);
    return Semantics(
      onTap: widget.onTap == null ? null : _handleTap,
      onLongPress: widget.onLongPress == null ? null : _handleLongPress,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: widget.behavior,
          excludeFromSemantics: true,
          onTap: widget.onTap == null ? null : _handleTap,
          onLongPress: widget.onLongPress == null ? null : _handleLongPress,
          onTapDown: (_) => _handleTapDown(),
          onTapUp: (_) => _handleTapUp(),
          onTapCancel: _handleTapUp,
          child: content,
        ),
      ),
    );
  }
}
