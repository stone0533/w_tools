import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/container.dart';
import 'button_style.dart';
import 'button_theme.dart';

export 'button_style.dart';
export 'button_styles.dart';
export 'button_theme.dart';

/// 纯点击区域组件。
///
/// 只负责交互、点击反馈与无障碍；视觉样式由 [WButtonStyle] 提供，
/// 运行时状态（enabled / loading）由本组件参数提供。
class WButton extends StatefulWidget {
  const WButton({
    super.key,
    this.style,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.loadingBuilder,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.opaque,
    required this.child,
  });

  /// 按钮样式；null 时使用 [WButtonTheme] 的 primary / 内置默认
  final WButtonStyle? style;

  /// 点击回调
  final GestureTapCallback? onTap;

  /// 长按回调
  final GestureLongPressCallback? onLongPress;

  /// 是否启用
  final bool enabled;

  /// 是否加载中；加载中不响应点击
  final bool loading;

  /// 加载中占位；默认小号 CircularProgressIndicator
  final WidgetBuilder? loadingBuilder;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 是否自动获取焦点
  final bool autofocus;

  /// 命中测试行为
  final HitTestBehavior behavior;

  /// 子组件
  final Widget child;

  @override
  State<WButton> createState() => _WButtonState();
}

class _WButtonState extends State<WButton> with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  AnimationController? _animationController;
  Animation<double>? _shakeAnimation;
  int _pressToken = 0;

  bool get _interactive => widget.enabled && !widget.loading;

  @override
  void dispose() {
    _pressed.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _pressed.value) {
      _pressed.value = false;
    }
    final style = _resolveStyle(context);
    _syncController(style);
  }

  WButtonStyle _resolveStyle(BuildContext context) {
    return widget.style ?? WButtonTheme.maybeOf(context)?.primary ?? const WButtonStyle();
  }

  void _syncController(WButtonStyle style) {
    final controller = _animationController;
    if (controller != null && controller.duration != style.animationDuration) {
      controller.duration = style.animationDuration;
    }
  }

  AnimationController _controllerFor(WButtonStyle style) {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: style.animationDuration,
        vsync: this,
      );
      _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.elasticOut,
        ),
      );
    } else if (_animationController!.duration != style.animationDuration) {
      _animationController!.duration = style.animationDuration;
    }
    return _animationController!;
  }

  Animation<double> _shakeFor(WButtonStyle style) {
    _controllerFor(style);
    return _shakeAnimation!;
  }

  void _shake(WButtonStyle style) {
    _controllerFor(style)
      ..reset()
      ..forward();
  }

  void _pulse(WButtonStyle style) {
    final token = ++_pressToken;
    _pressed.value = true;
    if (style.effect == WButtonEffectType.shake) _shake(style);
    Future<void>.delayed(style.animationDuration, () {
      if (mounted && token == _pressToken) _pressed.value = false;
    });
  }

  void _activate(WButtonStyle style) {
    if (!_interactive) return;
    _pulse(style);
    widget.onTap?.call();
  }

  void _onTapDown(WButtonStyle style) {
    if (!_interactive) return;
    _pressed.value = true;
    if (style.effect == WButtonEffectType.shake) _shake(style);
  }

  void _onTapUp() {
    if (!_interactive) return;
    _pressed.value = false;
  }

  Widget _visual(WButtonStyle style, bool pressed, Widget child) {
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
          animation: _shakeFor(style),
          builder: (context, child) {
            final offset = sin(_shakeAnimation!.value * 2 * pi * 3) * 4;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    style.validate();
    _syncController(style);
    final interactive = _interactive;

    final content = widget.loading
        ? (widget.loadingBuilder?.call(context) ??
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
        : widget.child;

    final container = style.container;
    final visualChild = container == null ? content : WContainer(config: container, child: content);

    return Semantics(
      button: true,
      enabled: interactive,
      label: style.semanticLabel,
      hint: style.semanticHint,
      onTap: interactive && widget.onTap != null ? () => _activate(style) : null,
      child: FocusableActionDetector(
        enabled: interactive,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
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
          behavior: widget.behavior,
          excludeFromSemantics: true,
          onTap: interactive ? widget.onTap : null,
          onLongPress: interactive ? widget.onLongPress : null,
          onTapDown: interactive ? (_) => _onTapDown(style) : null,
          onTapUp: interactive ? (_) => _onTapUp() : null,
          onTapCancel: interactive ? _onTapUp : null,
          child: ValueListenableBuilder<bool>(
            valueListenable: _pressed,
            builder: (context, pressed, _) => _visual(style, pressed, visualChild),
          ),
        ),
      ),
    );
  }
}
