import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/container.dart';
import 'text.dart';

/// 按钮效果类型枚举
///
/// 定义了 WButton 组件支持的各种点击效果类型
enum WButtonEffectType {
  /// 透明度变化效果：点击时子组件透明度降低
  opacity,

  /// 缩放效果：点击时子组件轻微缩小
  scale,

  /// 震动效果：点击时子组件产生震动动画
  shake,
}

/// 按钮配置类
///
/// 用于配置 WButton 组件的各种属性
/// 支持链式调用和配置缓存
class WButtonConfig {
  /// 静态缓存常用配置的模板，避免重复创建
  ///
  /// 缓存的是「模板」实例；[getCachedConfig] 对外返回其副本，调用方的修改不会污染缓存。
  static final Map<String, WButtonConfig> _configCache = {};

  /// 缓存清理阈值
  static const int _cacheSizeThreshold = 100;

  /// 清空缓存
  static void clearCache() {
    _configCache.clear();
  }

  /// 清理超出阈值的缓存
  static void trimCache() {
    if (_configCache.length > _cacheSizeThreshold) {
      // 保留最近使用的配置
      final keys = _configCache.keys.toList();
      // 计算需要移除的数量，确保不超过列表长度
      final removeCount = keys.length - _cacheSizeThreshold;
      for (int i = 0; i < removeCount && i < keys.length; i++) {
        _configCache.remove(keys[i]);
      }
    }
  }

  /// 获取缓存的配置或创建新配置
  ///
  /// - [key]：配置缓存键
  /// - [creator]：配置创建函数
  /// 返回：WButtonConfig 配置实例
  static WButtonConfig getCachedConfig(String key, WButtonConfig Function() creator) {
    // 定期清理缓存
    if (_configCache.length > _cacheSizeThreshold) {
      trimCache();
    }

    // 如果缓存存在，先移除再重新添加，确保在 LinkedHashMap 末尾（最近使用）
    if (_configCache.containsKey(key)) {
      final config = _configCache[key]!;
      _configCache.remove(key);
      _configCache[key] = config;
      // 返回副本：缓存实例保持不被调用方修改
      return config.copy();
    }

    final config = creator();
    _configCache[key] = config;
    // 返回副本：缓存实例保持不被调用方修改
    return config.copy();
  }

  /// 点击时的透明度，默认值为 0.7
  double _tapOpacity = 0.7;

  /// 动画持续时间，默认值为 100 毫秒
  Duration _animationDuration = const Duration(milliseconds: 100);

  /// 是否启用按钮，默认值为 true
  bool _enabled = true;

  /// 点击行为，默认值为 HitTestBehavior.opaque
  HitTestBehavior _behavior = HitTestBehavior.opaque;

  /// 按钮效果类型，默认值为 WButtonEffectType.opacity
  WButtonEffectType _effectType = WButtonEffectType.opacity;

  /// 缩放比例，默认值为 0.95
  double _scale = 0.95;

  /// 动画曲线，默认值为 Curves.easeInOut
  Curve _curve = Curves.easeInOut;

  /// 容器配置
  WContainerConfig? _containerConfig;

  /// 文本按钮的默认文本样式
  WTextConfig? _textButtonStyle;

  /// 设置点击时的透明度
  ///
  /// - [tapOpacity]：点击时的透明度
  set tapOpacity(double tapOpacity) {
    _tapOpacity = tapOpacity;
  }

  /// 设置动画持续时间
  ///
  /// - [animationDuration]：动画持续时间
  set animationDuration(Duration animationDuration) {
    _animationDuration = animationDuration;
  }

  /// 设置是否启用
  ///
  /// - [enabled]：是否启用
  set enabled(bool enabled) {
    _enabled = enabled;
  }

  /// 设置点击行为
  ///
  /// - [behavior]：点击行为
  set behavior(HitTestBehavior behavior) {
    _behavior = behavior;
  }

  /// 设置按钮效果类型
  ///
  /// - [effectType]：按钮效果类型
  set effectType(WButtonEffectType effectType) {
    _effectType = effectType;
  }

  /// 设置缩放比例
  ///
  /// - [scale]：缩放比例
  set scale(double scale) {
    // 确保缩放比例在合理范围内
    _scale = scale.clamp(0.1, 1.0);
  }

  /// 设置动画曲线
  ///
  /// - [curve]：动画曲线
  set curve(Curve curve) {
    _curve = curve;
  }

  /// 设置容器配置
  ///
  /// - [containerConfig]：容器配置
  set containerConfig(WContainerConfig containerConfig) {
    _containerConfig = containerConfig;
  }

  /// 设置文本按钮的默认文本样式
  set textButtonStyle(WTextConfig textButtonStyle) {
    _textButtonStyle = textButtonStyle;
  }

  /// 复制一份独立配置
  ///
  /// 返回新实例，避免多个调用方共享同一个可变配置对象。
  WButtonConfig copy() {
    return WButtonConfig()
      .._tapOpacity = _tapOpacity
      .._animationDuration = _animationDuration
      .._enabled = _enabled
      .._behavior = _behavior
      .._effectType = _effectType
      .._scale = _scale
      .._curve = _curve
      .._containerConfig = _containerConfig
      .._textButtonStyle = _textButtonStyle;
  }

  /// 用文本构建按钮（以本配置创建 WButton + WText 子组件）
  ///
  /// - [text]：按钮文本
  /// - [onTap]：点击回调
  /// - [textStyle]：文本配置，未传时回退到 [textButtonStyle]
  WButton buildText({
    required String text,
    GestureTapCallback? onTap,
    WTextConfig? textStyle,
  }) {
    return WButton(
      config: this,
      onTap: onTap,
      child: WText(
        text: text,
        config: textStyle ?? _textButtonStyle,
      ),
    );
  }

  /// 快捷方法：创建透明度效果配置
  ///
  /// - [opacity]：透明度值
  /// 返回：WButtonConfig 配置实例
  static WButtonConfig opacityEffect({double opacity = 0.7}) {
    return getCachedConfig('opacity_$opacity', () {
      return WButtonConfig()
        ..effectType = WButtonEffectType.opacity
        ..tapOpacity = opacity;
    });
  }

  /// 快捷方法：创建缩放效果配置
  ///
  /// - [scale]：缩放比例
  /// 返回：WButtonConfig 配置实例
  static WButtonConfig scaleEffect({double scale = 0.95}) {
    return getCachedConfig('scale_$scale', () {
      return WButtonConfig()
        ..effectType = WButtonEffectType.scale
        ..scale = scale;
    });
  }

  /// 快捷方法：创建震动效果配置
  ///
  /// 返回：WButtonConfig 配置实例
  static WButtonConfig shakeEffect() {
    return getCachedConfig('shake', () {
      return WButtonConfig()..effectType = WButtonEffectType.shake;
    });
  }
}

/// 点击效果组件
///
/// 为子组件添加点击时的视觉反馈效果，支持透明度 / 缩放 / 震动三种类型。
/// 提供 `button` 语义、鼠标光标与 Enter / Space 键盘激活；
/// 禁用时不再响应点击与键盘操作。
class WButton extends StatefulWidget {
  /// 子组件，将应用点击效果
  final Widget child;

  /// 点击回调，当按钮被点击时触发
  final GestureTapCallback? onTap;

  /// 长按回调，当按钮被长按时触发
  final GestureLongPressCallback? onLongPress;

  /// 按钮配置，用于自定义按钮的行为和效果
  final WButtonConfig? config;

  /// 创建点击效果组件
  ///
  /// - [key]：组件键
  /// - [child]：子组件，必需
  /// - [onTap]：点击回调，可选
  /// - [onLongPress]：长按回调，可选
  /// - [config]：按钮配置，可选
  const WButton({
    super.key,
    this.config,
    this.onTap,
    this.onLongPress,
    required this.child,
  });

  @override
  State<WButton> createState() => _WButtonState();
}

/// WButton 组件的状态类
class _WButtonState extends State<WButton> with SingleTickerProviderStateMixin {
  /// 点击状态通知器，用于通知子组件点击状态的变化
  final ValueNotifier<bool> _isTappedNotifier = ValueNotifier<bool>(false);

  /// 动画控制器（仅 shake 效果需要时才创建，懒加载）
  AnimationController? _animationController;

  /// 震动动画（仅 shake 效果需要时才创建，懒加载）
  Animation<double>? _shakeAnimation;

  /// 缓存的配置对象，避免每次 build 时都创建新实例
  WButtonConfig? _cachedConfig;

  /// 默认动画持续时间
  static const _defaultDuration = Duration(milliseconds: 100);

  AnimationController get _controller {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: widget.config?._animationDuration ?? _defaultDuration,
        vsync: this,
      );
      _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.elasticOut,
        ),
      );
    }
    return _animationController!;
  }

  Animation<double> get _shakeAnim {
    // 确保 controller 已创建（会同时创建 shakeAnimation）
    _controller;
    return _shakeAnimation!;
  }

  @override
  void dispose() {
    // 清理资源
    _isTappedNotifier.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当配置变化时更新缓存
    if (oldWidget.config != widget.config) {
      _cachedConfig = null;
      // 更新动画控制器的持续时间（仅在已创建时）
      if (_animationController != null) {
        _animationController!.duration = widget.config?._animationDuration ?? _defaultDuration;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 缓存配置对象，避免每次 build 时都创建新实例
    _cachedConfig ??= widget.config ?? WButtonConfig();
    final config = _cachedConfig!;

    // 构建带有点击效果的容器
    return Semantics(
      button: true,
      enabled: config._enabled,
      child: FocusableActionDetector(
        enabled: config._enabled,
        mouseCursor: config._enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        // 支持键盘 Enter / Space 触发点击
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: config._enabled ? widget.onTap : null,
          onLongPress: config._enabled ? widget.onLongPress : null,
          behavior: config._behavior,
          onTapDown: config._enabled
              ? (details) {
                  _isTappedNotifier.value = true;
                  if (config._effectType == WButtonEffectType.shake) {
                    _controller.reset();
                    _controller.forward();
                  }
                }
              : null,
          onTapUp: config._enabled
              ? (details) {
                  _isTappedNotifier.value = false;
                }
              : null,
          onTapCancel: config._enabled
              ? () {
                  _isTappedNotifier.value = false;
                }
              : null,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isTappedNotifier,
            builder: (context, isTapped, child) {
              return _buildEffect(config, isTapped, child!);
            },
            child: _buildButtonContainer(config, widget.child),
          ),
        ),
      ),
    );
  }

  /// 构建按钮容器，应用配置的样式
  ///
  /// - [config]：按钮配置
  /// - [child]：子组件
  /// 返回：Widget 带有样式的按钮容器
  Widget _buildButtonContainer(WButtonConfig config, Widget child) {
    // 如果没有设置容器配置，直接返回子组件
    if (config._containerConfig == null) {
      return child;
    }

    // 构建带有样式的容器
    return WContainer(
      config: config._containerConfig!,
      child: child,
    );
  }

  /// 根据效果类型构建不同的动画效果
  ///
  /// - [config]：按钮配置
  /// - [isTapped]：是否被点击
  /// - [child]：子组件
  /// 返回：Widget 带有动画效果的组件
  Widget _buildEffect(WButtonConfig config, bool isTapped, Widget child) {
    if (config._effectType == WButtonEffectType.opacity) {
      return _buildOpacityEffect(config, isTapped, child);
    } else if (config._effectType == WButtonEffectType.scale) {
      return _buildScaleEffect(config, isTapped, child);
    } else if (config._effectType == WButtonEffectType.shake) {
      return _buildShakeEffect(child);
    }
    // 确保方法总是有返回值
    return child;
  }

  /// 构建透明度效果
  ///
  /// - [config]：按钮配置
  /// - [isTapped]：是否被点击
  /// - [child]：子组件
  /// 返回：Widget 带有透明度动画的组件
  Widget _buildOpacityEffect(WButtonConfig config, bool isTapped, Widget child) {
    return AnimatedOpacity(
      opacity: isTapped ? config._tapOpacity : 1.0,
      duration: config._animationDuration,
      curve: config._curve,
      child: child,
    );
  }

  /// 构建缩放效果
  ///
  /// - [config]：按钮配置
  /// - [isTapped]：是否被点击
  /// - [child]：子组件
  /// 返回：Widget 带有缩放动画的组件
  Widget _buildScaleEffect(WButtonConfig config, bool isTapped, Widget child) {
    return AnimatedScale(
      scale: isTapped ? config._scale : 1.0,
      duration: config._animationDuration,
      curve: config._curve,
      child: child,
    );
  }

  /// 构建震动效果
  ///
  /// - [child]：子组件
  /// 返回：Widget 带有震动动画的组件
  Widget _buildShakeEffect(Widget child) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        // 使用 sin 函数计算震动效果，确保值在有效范围内
        final value = _shakeAnim.value;
        final offset = sin(value * 2 * pi * 3) * 4;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}
