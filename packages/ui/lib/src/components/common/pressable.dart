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
  });

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

  @override
  State<WPressable> createState() => _WPressableState();
}

class _WPressableState extends State<WPressable> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
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
    final enabled = widget.enabled;
    final content = IgnorePointer(
      ignoring: !enabled,
      child: _effect(widget.child),
    );
    return Semantics(
      onTap: enabled ? widget.onTap : null,
      onLongPress: enabled ? widget.onLongPress : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: widget.behavior,
          excludeFromSemantics: true,
          onTap: enabled ? widget.onTap : null,
          onLongPress: enabled ? widget.onLongPress : null,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: content,
        ),
      ),
    );
  }
}
