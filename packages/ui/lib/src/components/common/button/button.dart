import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../layout/container.dart';
import 'button_size.dart';
import 'button_style.dart';
import 'button_styles.dart';
import '../text.dart';
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
    this.semanticLabel,
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
    this.child,
  }) : assert(
          child != null || label != null || icon != null,
          'WButton: child、label、icon 至少提供一个',
        );

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

  /// 显式无障碍标签；纯图标按钮建议提供
  final String? semanticLabel;

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
    String? semanticLabel,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton(
        variant: 'primary',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        semanticLabel: semanticLabel,
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
    String? semanticLabel,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton(
        variant: 'secondary',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        semanticLabel: semanticLabel,
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
    String? semanticLabel,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton(
        variant: 'text',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        semanticLabel: semanticLabel,
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
    String? semanticLabel,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton(
        variant: 'danger',
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        semanticLabel: semanticLabel,
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
    String? semanticLabel,
    bool enabled = true,
    bool loading = false,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
  }) =>
      WButton(
        variant: variant,
        label: label,
        key: key,
        style: style,
        size: size,
        sizeName: sizeName,
        semanticLabel: semanticLabel,
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
    String? semanticLabel,
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
      WButton(
        icon: icon,
        label: label,
        semanticLabel: semanticLabel,
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

  @override
  State<WButton> createState() => _WButtonState();
}

class _WButtonState extends State<WButton> with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  AnimationController? _animationController;
  Animation<double>? _shakeAnimation;
  int _pressToken = 0;
  Timer? _pressTimer;
  bool _focused = false;
  bool _hovered = false;
  WButtonStyle? _cachedStyle;
  Object? _cachedStyleKey;

  bool get _interactive => widget.enabled && !widget.loading;

  @override
  void dispose() {
    _pressTimer?.cancel();
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
    final key = Object.hash(
      widget.style,
      widget.variant,
      widget.size,
      widget.sizeName,
      widget.semanticLabel,
      widget.label,
      widget.icon,
      widget.tooltip,
      theme,
    );
    if (_cachedStyle != null && _cachedStyleKey == key) return _cachedStyle!;
    final fallback = switch (widget.variant) {
      'primary' => WButtonStyles.primary,
      'secondary' => WButtonStyles.secondary,
      'text' => WButtonStyles.text,
      'danger' => WButtonStyles.danger,
      _ => WButtonStyle(),
    };
    if (widget.variant != null &&
        theme != null &&
        theme.resolveStyle(widget.variant) == null &&
        !const {'primary', 'secondary', 'text', 'danger'}.contains(widget.variant)) {
      assert(false, 'WButton: 未注册的 variant "${widget.variant}"');
    }
    final namedSize = theme?.resolveSize(widget.sizeName);
    if (widget.sizeName != null) {
      assert(namedSize != null, 'WButton: 未注册的 sizeName "${widget.sizeName}"');
    }
    final base = widget.style ??
        theme?.resolveStyle(widget.variant) ??
        (widget.variant != null ? fallback : WButtonStyle());
    final size = widget.size ??
        namedSize ??
        (widget.variant != null ? (theme?.defaultSize ?? WButtonSize.medium) : null);
    final semantic = widget.semanticLabel ??
        (widget.label == null && widget.icon != null ? widget.tooltip : null);
    final resolved = semantic == null ? base.copy() : base.copy().copyWith(semanticLabel: semantic);
    final sized = resolved.applySize(size);
    assert(
      widget.icon == null || widget.label != null || sized.semanticLabel != null,
      'WButton.icon: 纯图标按钮请提供 semanticLabel 或 tooltip',
    );
    _cachedStyle = sized;
    _cachedStyleKey = key;
    return sized;
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
    _pressTimer?.cancel();
    _setPressed(true);
    if (style.effect == WButtonEffectType.shake) _shake(style);
    _pressTimer = Timer(style.animationDuration, () {
      if (mounted && token == _pressToken) _setPressed(false);
    });
  }

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    if (widget.enableFeedback) {
      HapticFeedback.selectionClick();
    }
    onTap();
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

  Widget _overlay(
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

  Widget _tapTarget(Widget child, WButtonStyle style) {
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
    final inner = _content(context, style, child);
    final padded = style.padding != null ? Padding(padding: style.padding!, child: inner) : inner;
    final content = container == null ? padded : WContainer(config: container, child: padded);

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
        result = _overlay(result, hoverColor, style.overlayBorderRadius);
      }
      if (_focused && interactive) {
        result = _overlay(result, focusColor, style.overlayBorderRadius);
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
            builder: (context, pressed, _) => _tapTarget(buildVisual(pressed), style),
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
