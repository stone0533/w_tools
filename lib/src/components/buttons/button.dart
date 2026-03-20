import 'package:flutter/material.dart';
import 'dart:math';

import 'package:w_tools/src/components/components.dart';

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
/// 支持链式调用
class WButtonConfig {
  /// 静态缓存常用配置，避免重复创建
  static final Map<String, WButtonConfig> _configCache = {};

  /// 缓存清理阈值
  static const int _cacheSizeThreshold = 100;

  /// 清理缓存
  ///
  /// @return void
  static void clearCache() {
    _configCache.clear();
  }

  /// 清理超出阈值的缓存
  ///
  /// @return void
  static void trimCache() {
    if (_configCache.length > _cacheSizeThreshold) {
      // 保留最近使用的配置
      final keys = _configCache.keys.toList();
      for (int i = 0; i < keys.length - _cacheSizeThreshold; i++) {
        _configCache.remove(keys[i]);
      }
    }
  }

  /// 获取缓存的配置或创建新配置
  ///
  /// @param key 配置缓存键
  /// @param creator 配置创建函数
  /// @return WButtonConfig 配置实例
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
      return config;
    }

    final config = creator();
    _configCache[key] = config;
    return config;
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

  WTextConfig? _textButtonTitleStyle;

  /// 设置点击时的透明度
  ///
  /// @param tapOpacity 点击时的透明度
  /// @return WButtonConfig 配置实例，用于链式调用
  set tapOpacity(double tapOpacity) {
    _tapOpacity = tapOpacity;
  }

  /// 设置动画持续时间
  ///
  /// @param animationDuration 动画持续时间
  /// @return WButtonConfig 配置实例，用于链式调用
  set animationDuration(Duration animationDuration) {
    _animationDuration = animationDuration;
  }

  /// 设置是否启用
  ///
  /// @param enabled 是否启用
  /// @return WButtonConfig 配置实例，用于链式调用
  set enabled(bool enabled) {
    _enabled = enabled;
  }

  /// 设置点击行为
  ///
  /// @param behavior 点击行为
  /// @return WButtonConfig 配置实例，用于链式调用
  set behavior(HitTestBehavior behavior) {
    _behavior = behavior;
  }

  /// 设置按钮效果类型
  ///
  /// @param effectType 按钮效果类型
  /// @return WButtonConfig 配置实例，用于链式调用
  set effectType(WButtonEffectType effectType) {
    _effectType = effectType;
  }

  /// 设置缩放比例
  ///
  /// @param scale 缩放比例
  /// @return WButtonConfig 配置实例，用于链式调用
  set scale(double scale) {
    // 确保缩放比例在合理范围内
    _scale = scale.clamp(0.1, 1.0);
  }

  /// 设置动画曲线
  ///
  /// @param curve 动画曲线
  /// @return WButtonConfig 配置实例，用于链式调用
  set curve(Curve curve) {
    _curve = curve;
  }

  /// 设置容器配置
  ///
  /// @param containerConfig 容器配置
  /// @return WButtonConfig 配置实例，用于链式调用
  set containerConfig(WContainerConfig containerConfig) {
    _containerConfig = containerConfig;
  }

  set textButtonStyle(WTextConfig textButtonStyle) {
    _textButtonTitleStyle = textButtonStyle;
  }


  WButton buildTextButton({
    required String text,
    GestureTapCallback? onTap,
    WTextConfig? textStyle,
  }) {
    return WButton(
      config: this,
      onTap: onTap,
      child: WText(
        text: text,
        config: textStyle ?? _textButtonTitleStyle,
      ),
    );
  }

  /// 快捷方法：创建透明度效果配置
  ///
  /// @param opacity 透明度值
  /// @return WButtonConfig 配置实例
  static WButtonConfig opacityEffect({double opacity = 0.7}) {
    return getCachedConfig('opacity_$opacity', () {
      return WButtonConfig()
        ..effectType = WButtonEffectType.opacity
        ..tapOpacity = opacity;
    });
  }

  /// 快捷方法：创建缩放效果配置
  ///
  /// @param scale 缩放比例
  /// @return WButtonConfig 配置实例
  static WButtonConfig scaleEffect({double scale = 0.95}) {
    return getCachedConfig('scale_$scale', () {
      return WButtonConfig()
        ..effectType = WButtonEffectType.scale
        ..scale = scale;
    });
  }

  /// 快捷方法：创建震动效果配置
  ///
  /// @return WButtonConfig 配置实例
  static WButtonConfig shakeEffect() {
    return getCachedConfig('shake', () {
      return WButtonConfig()..effectType = WButtonEffectType.shake;
    });
  }
}

/// 点击效果组件
///
/// 为子组件添加点击时的视觉反馈效果，支持多种效果类型
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
  /// @param key 组件键
  /// @param child 子组件，必需
  /// @param onTap 点击回调，可选
  /// @param onLongPress 长按回调，可选
  /// @param config 按钮配置，可选
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

  /// 动画控制器，用于控制震动效果的动画
  late final AnimationController _animationController;

  /// 震动动画，用于实现震动效果
  late final Animation<double> _shakeAnimation;

  /// 缓存的配置对象，避免每次 build 时都创建新实例
  WButtonConfig? _cachedConfig;

  /// 默认动画持续时间
  static const _defaultDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: widget.config?._animationDuration ?? _defaultDuration,
      vsync: this,
    );

    // 震动动画
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    // 清理资源
    _isTappedNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当配置变化时更新缓存
    if (oldWidget.config != widget.config) {
      _cachedConfig = null;
      // 更新动画控制器的持续时间
      _animationController.duration = widget.config?._animationDuration ?? _defaultDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 缓存配置对象，避免每次 build 时都创建新实例
    _cachedConfig ??= widget.config ?? WButtonConfig();
    final config = _cachedConfig!;

    // 构建带有点击效果的容器
    Widget buttonContent = FocusableActionDetector(
      enabled: config._enabled,
      child: GestureDetector(
        onTap: config._enabled ? widget.onTap : null,
        onLongPress: config._enabled ? widget.onLongPress : null,
        behavior: config._behavior,
        onTapDown: config._enabled
            ? (details) {
                _isTappedNotifier.value = true;
                if (config._effectType == WButtonEffectType.shake) {
                  _animationController.reset();
                  _animationController.forward();
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
    );

    return buttonContent;
  }

  /// 构建按钮容器，应用配置的样式
  ///
  /// @param config 按钮配置
  /// @param child 子组件
  /// @return Widget 带有样式的按钮容器
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
  /// @param config 按钮配置
  /// @param isTapped 是否被点击
  /// @param child 子组件
  /// @return Widget 带有动画效果的组件
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
  /// @param config 按钮配置
  /// @param isTapped 是否被点击
  /// @param child 子组件
  /// @return Widget 带有透明度动画的组件
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
  /// @param config 按钮配置
  /// @param isTapped 是否被点击
  /// @param child 子组件
  /// @return Widget 带有缩放动画的组件
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
  /// @param child 子组件
  /// @return Widget 带有震动动画的组件
  Widget _buildShakeEffect(Widget child) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // 使用 sin 函数计算震动效果，确保值在有效范围内
        final value = _shakeAnimation.value;
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
