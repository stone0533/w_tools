import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/container.dart';
import 'button_size.dart';
import 'button_style.dart';
import 'button_styles.dart';
import 'text.dart';
import 'button_theme.dart';

export 'button_size.dart';
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
    this.variant,
    this.label,
    this.icon,
    this.size,
    this.sizeName,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onFocusChange,
    this.onHover,
    this.onPressedChanged,
    this.enabled = true,
    this.loading = false,
    this.loadingBuilder,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.opaque,
    this.tooltip,
    this.enableFeedback = true,
    required this.child,
  });

  /// 按钮样式；null 时使用 [WButtonTheme] 的 primary / 内置默认
  final WButtonStyle? style;

  /// 变体名（primary / secondary / text / danger 或项目自定义）
  final String? variant;

  /// 快捷构造的文本 / 图标
  final String? label;
  final IconData? icon;

  /// 尺寸；优先级高于 sizeName
  final WButtonSize? size;

  /// 主题里注册的尺寸名
  final String? sizeName;

  /// 点击回调
  final GestureTapCallback? onTap;

  /// 长按回调
  final GestureLongPressCallback? onLongPress;

  /// 次要点击（右键 / 桌面端）
  final GestureTapCallback? onSecondaryTap;

  /// 按下 / 抬起 / 取消（用于埋点、联动）
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;

  /// 焦点 / hover 变化
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHover;

  /// 按下状态变化
  final ValueChanged<bool>? onPressedChanged;

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

  /// 长按提示（桌面端/无障碍）
  final String? tooltip;

  /// 是否启用点击反馈（触觉）
  final bool enableFeedback;

  /// 子组件（快捷构造时可为空）
  final Widget? child;

  /// 快捷构造：primary / secondary / text / danger 变体
  factory WButton.primary(
    String label, {
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        variant: 'primary',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  factory WButton.secondary(
    String label, {
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        variant: 'secondary',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  factory WButton.text(
    String label, {
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        variant: 'text',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  factory WButton.danger(
    String label, {
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        variant: 'danger',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  factory WButton.variant(
    String variant,
    String label, {
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        variant: variant,
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  factory WButton.icon(
    IconData icon, {
    String? label,
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton._preset(
        icon: icon,
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        enabled: enabled,
        loading: loading,
        onTap: onTap,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
      );

  static WButton _preset({
    String? variant,
    String? label,
    IconData? icon,
    Key? key,
    WButtonStyle? style,
    WButtonSize? size,
    String? sizeName,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) {
    return WButton._(
      key: key,
      variant: variant,
      label: label,
      icon: icon,
      style: style,
      size: size,
      sizeName: sizeName,
      enabled: enabled,
      loading: loading,
      onTap: onTap,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      enableFeedback: enableFeedback,
      child: null,
    );
  }

  const WButton._({
    super.key,
    this.style,
    this.variant,
    this.label,
    this.icon,
    this.size,
    this.sizeName,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback = true,
    this.child,
  })  : onSecondaryTap = null,
        onTapDown = null,
        onTapUp = null,
        onTapCancel = null,
        onFocusChange = null,
        onHover = null,
        onPressedChanged = null,
        loadingBuilder = null,
        behavior = HitTestBehavior.opaque;

  @override
  State<WButton> createState() => _WButtonState();
}

class _WButtonState extends State<WButton> with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  AnimationController? _animationController;
  Animation<double>? _shakeAnimation;
  int _pressToken = 0;
  bool _focused = false;
  bool _hovered = false;

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
    if (!_interactive) {
      _setPressed(false);
      _focused = false;
      _hovered = false;
    }
    _syncController(_resolveStyle(context));
  }

  WButtonStyle _resolveStyle(BuildContext context) {
    final theme = WButtonTheme.maybeOf(context);
    final fallback = switch (widget.variant) {
      'primary' => WButtonStyles.primary,
      'secondary' => WButtonStyles.secondary,
      'text' => WButtonStyles.text,
      'danger' => WButtonStyles.danger,
      _ => const WButtonStyle(),
    };
    final base = widget.style ??
        theme?.resolveStyle(widget.variant) ??
        (widget.variant != null ? fallback : const WButtonStyle());
    final size = widget.size ??
        theme?.resolveSize(widget.sizeName) ??
        (widget.variant != null ? (theme?.defaultSize ?? WButtonSize.medium) : null);
    return base.applySize(size);
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

  void _setPressed(bool value) {
    if (_pressed.value == value) return;
    _pressed.value = value;
    widget.onPressedChanged?.call(value);
  }

  void _pulse(WButtonStyle style) {
    final token = ++_pressToken;
    _setPressed(true);
    if (style.effect == WButtonEffectType.shake) _shake(style);
    Future<void>.delayed(style.animationDuration, () {
      if (mounted && token == _pressToken) _setPressed(false);
    });
  }

  void _handleTap() {
    if (widget.enableFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _activate(WButtonStyle style) {
    if (!_interactive) return;
    _pulse(style);
    _handleTap();
  }

  void _onTapDown(WButtonStyle style, TapDownDetails details) {
    if (!_interactive) return;
    widget.onTapDown?.call(details);
    _setPressed(true);
    if (style.effect == WButtonEffectType.shake) _shake(style);
  }

  void _onTapUp(TapUpDetails details) {
    if (!_interactive) return;
    widget.onTapUp?.call(details);
    _setPressed(false);
  }

  void _onTapCancel() {
    if (!_interactive) return;
    widget.onTapCancel?.call();
    _setPressed(false);
  }

  Widget _label(BuildContext context, WButtonStyle style) {
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

  Widget _loading(BuildContext context, WButtonStyle style) {
    final child = widget.loadingBuilder?.call(context) ??
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

  Widget _overlay(Widget child, Color color) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: color),
          ),
        ),
      ],
    );
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

  Widget _content(BuildContext context, WButtonStyle style, Widget child) {
    if (!widget.loading) return child;

    // loading 时保留 child 占位，避免按钮尺寸跳动。
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: Opacity(opacity: 0, child: child),
        ),
        _loading(context, style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    style.validate();
    _syncController(style);
    final interactive = _interactive;
    final theme = Theme.of(context);

    final child = widget.child ?? _label(context, style);
    final container = style.container?.copy();
    final content = container == null
        ? _content(context, style, child)
        : WContainer(config: container, child: _content(context, style, child));

    Widget visualChild = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: style.minWidth,
        minHeight: style.minHeight,
      ),
      child: content,
    );

    // 禁用时同时阻断 WButton 与 child 的交互。
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
      var result = _visual(style, pressed, visualChild);
      if (_hovered && interactive) {
        result = _overlay(result, hoverColor);
      }
      if (_focused && interactive) {
        result = _overlay(result, focusColor);
      }
      return result;
    }

    Widget result = Semantics(
      button: true,
      enabled: interactive,
      label: style.semanticLabel,
      hint: style.semanticHint,
      onTap: interactive && widget.onTap != null ? () => _activate(style) : null,
      onLongPress: interactive && widget.onLongPress != null ? widget.onLongPress : null,
      child: FocusableActionDetector(
        enabled: interactive,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onFocusChange: widget.onFocusChange,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) {
          setState(() => _hovered = value);
          widget.onHover?.call(value);
        },
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
          onTap: interactive ? _handleTap : null,
          onLongPress: interactive ? widget.onLongPress : null,
          onSecondaryTap: interactive ? widget.onSecondaryTap : null,
          onTapDown: interactive ? (details) => _onTapDown(style, details) : null,
          onTapUp: interactive ? _onTapUp : null,
          onTapCancel: interactive ? _onTapCancel : null,
          child: ValueListenableBuilder<bool>(
            valueListenable: _pressed,
            builder: (context, pressed, _) => buildVisual(pressed),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}
