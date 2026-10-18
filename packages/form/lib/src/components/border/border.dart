import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../form_builder.dart';
import 'border_layout.dart';

/// WFormBorder 组件是一个表单边框容器，用于为表单输入添加统一的边框样式和错误提示
///
/// 该组件支持以下特性：
/// - 可配置的边框样式（颜色、宽度、圆角）
/// - 支持只读状态和错误状态
/// - 支持透明背景
/// - 支持提示文本和错误文本
class WFormBorder extends StatefulWidget {
  /// 创建表单边框容器
  ///
  /// [config] 为 null 时继承祖先 [WFormBuilder.formBorderConfig]。
  const WFormBorder({
    super.key,
    this.config,
    required this.child,
    this.hintTextList,
    this.isReadOnly,
    this.isTransparentBackground,
    this.isFocused,
  });

  /// 子组件
  final Widget child;

  /// 提示文本列表
  final List<String>? hintTextList;

  /// 是否只读
  final bool? isReadOnly;

  /// 是否透明背景
  final bool? isTransparentBackground;

  /// 是否聚焦
  final bool? isFocused;

  /// 边框配置（为 null 时继承祖先 WFormBuilder.formBorderConfig）
  final WFormBorderConfig? config;

  @override
  State<WFormBorder> createState() => WFormBorderState();
}

/// WFormBorder 的状态类
class WFormBorderState extends State<WFormBorder> {
  /// 当前生效的边框配置（显式传入或继承自 [WFormBuilder.formBorderConfig]）
  late WFormBorderConfig config;

  /// 是否有错误
  bool isError = false;

  /// 消息列表（提示或错误）
  List<String>? messageList;

  /// 装饰缓存键（null 表示尚未计算）
  ///
  /// 用 record 承载全部判定条件，减少字段数量，并让「透明态装饰为 null」也能命中缓存。
  ({bool? transparent, bool? readOnly, bool isError, bool? focused})? _decorationKey;

  /// 缓存的装饰对象
  WFormBorderDecoration? _cachedDecoration;

  /// 缓存的 BoxDecoration 对象
  BoxDecoration? _cachedBoxDecoration;

  /// 缓存的边框圆角
  BorderRadius? _cachedBorderRadius;

  /// 配置内容快照（用于检测同一实例的原地修改）
  late Object _configSnapshot;

  /// 设置错误状态
  ///
  /// 无状态变化时直接返回，避免校验通过时对已无错误的字段重复触发重建。
  void setError(bool value, {List<String>? errorTextList}) {
    // 清除错误且当前本就无错误：无变化，跳过重建
    if (!value && !isError) return;
    setState(() {
      isError = value;
      messageList = value ? errorTextList : widget.hintTextList;
    });
  }

  @override
  void initState() {
    super.initState();
    // initState 中不能读取 InheritedWidget：先用显式配置或空配置占位，
    // 继承 WFormBuilder.formBorderConfig 在 didChangeDependencies 中完成
    config = widget.config ?? WFormBorderConfig();
    _configSnapshot = _snapshotOf(config);
    messageList = widget.hintTextList;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncConfig();
  }

  @override
  void didUpdateWidget(WFormBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncConfig();
    // 非错误态下同步父级传入的新提示文本
    if (!isError && !listEquals(widget.hintTextList, oldWidget.hintTextList)) {
      messageList = widget.hintTextList;
    }
  }

  /// 同步生效配置：显式传入优先，否则继承 [WFormBuilder.formBorderConfig]
  ///
  /// 比较内容快照而非实例身份，配置被原地修改时只要组件重建即可生效。
  void _syncConfig() {
    final resolved = widget.config ?? WFormBuilder.borderConfigOf(context) ?? WFormBorderConfig();
    final snapshot = _snapshotOf(resolved);
    if (snapshot == _configSnapshot) return;
    config = resolved;
    _configSnapshot = snapshot;
    _decorationKey = null; // 失效装饰缓存
  }

  /// 生成配置内容快照
  ///
  /// 装饰与构建器都是「整体替换」的不可变值，用引用比较即可；
  /// 因此能检测出 `config.errorDecoration = ...` 这类原地修改。
  Object _snapshotOf(WFormBorderConfig c) => (
    c._defaultDecoration,
    c._readOnlyDecoration,
    c._errorDecoration,
    c._focusedDecoration,
    c._hintBuilder,
    c._errorBuilder,
    c._layout,
  );

  /// 获取当前状态对应的装饰（带缓存，状态未变时复用上次结果）
  WFormBorderDecoration? _getDecoration() {
    final key = (
      transparent: widget.isTransparentBackground,
      readOnly: widget.isReadOnly,
      isError: isError,
      focused: widget.isFocused,
    );

    if (key == _decorationKey) {
      return _cachedDecoration;
    }
    _decorationKey = key;

    WFormBorderDecoration? decoration;
    if (isError) {
      // 错误态优先于透明背景：校验反馈不应因背景透明而丢失
      decoration = config._errorDecoration ?? config._defaultDecoration;
    } else if (widget.isTransparentBackground == true) {
      decoration = null;
    } else if (widget.isReadOnly == true) {
      decoration = config._readOnlyDecoration ?? config._defaultDecoration;
    } else if (widget.isFocused == true) {
      decoration = config._focusedDecoration ?? config._defaultDecoration;
    } else {
      decoration = config._defaultDecoration;
    }

    _cachedDecoration = decoration;
    _cachedBoxDecoration = decoration?.toBoxDecoration();
    _cachedBorderRadius = decoration?.borderRadius;

    return decoration;
  }

  /// 当前状态的 BoxDecoration（内部先确保装饰已计算）
  BoxDecoration? _getBoxDecoration() {
    _getDecoration();
    return _cachedBoxDecoration;
  }

  /// 当前状态的边框圆角（内部先确保装饰已计算）
  BorderRadius? _getBorderRadius() {
    _getDecoration();
    return _cachedBorderRadius;
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _getBoxDecoration();
    final borderRadius = _getBorderRadius();

    // 1. 先裁剪子组件，再套装饰：保证边框本身不被圆角裁掉
    Widget child = widget.child;
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius, child: child);
    }
    if (decoration != null) {
      child = DecoratedBox(decoration: decoration, child: child);
    }

    // 2. 按状态构建消息
    final hasMessage = messageList?.isNotEmpty ?? false;
    final Widget message;
    if (!hasMessage) {
      message = const SizedBox.shrink();
    } else if (isError) {
      message = config._errorBuilder?.call(messageList) ?? const SizedBox.shrink();
    } else {
      message = config._hintBuilder?.call(messageList) ?? const SizedBox.shrink();
    }

    // 3. 交给布局策略组装
    return config._layout.build(
      context,
      WFormBorderLayoutData(
        child: child,
        message: message,
        hasMessage: hasMessage,
        isError: isError,
        isReadOnly: widget.isReadOnly ?? false,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// 表单边框配置类，定义边框的样式和构建器
///
/// 默认不包含任何装饰与构建器（全部为 null），外观完全由显式配置决定。
///
/// 该配置按**引用**被 [WFormBorder] 捕获：
/// - 替换实例（如 `cfg = cfg.copyWith(...)`）会立即触发更新；
/// - 原地修改（`cfg.errorDecoration = ...`）只会在组件随后重建时生效，
///   若要确保立即生效，请替换实例。
///
/// [copyWith] 的 null 参数表示「保持不变」；要清空某个装饰，请使用 setter：
/// `cfg.copy()..errorDecoration = null`。
class WFormBorderConfig {
  /// 默认状态的装饰
  WFormBorderDecoration? _defaultDecoration;

  /// 只读状态的装饰
  WFormBorderDecoration? _readOnlyDecoration;

  /// 错误状态的装饰
  WFormBorderDecoration? _errorDecoration;

  /// 聚焦状态的装饰
  WFormBorderDecoration? _focusedDecoration;

  /// 提示文本构建器（null 表示不渲染提示文本）
  Widget Function(List<String>? list)? _hintBuilder;

  /// 错误文本构建器（null 表示不渲染错误文本）
  Widget Function(List<String>? list)? _errorBuilder;

  /// 边框与消息的布局策略
  WFormBorderLayout _layout = WFormBorderLayout.column;

  /// 创建边框配置
  ///
  /// 不内置任何默认值：所有装饰与构建器默认为 null，
  /// 未配置的状态不渲染装饰，外观完全由调用方配置决定。
  WFormBorderConfig();

  /// 设置默认状态装饰
  set defaultDecoration(WFormBorderDecoration? value) {
    _defaultDecoration = value;
  }

  /// 设置只读状态装饰
  set readOnlyDecoration(WFormBorderDecoration? value) {
    _readOnlyDecoration = value;
  }

  /// 设置错误状态装饰
  set errorDecoration(WFormBorderDecoration? value) {
    _errorDecoration = value;
  }

  /// 设置聚焦状态装饰
  set focusedDecoration(WFormBorderDecoration? value) {
    _focusedDecoration = value;
  }

  /// 设置提示文本构建器（null 表示不渲染提示文本）
  set hintBuilder(Widget Function(List<String>? list)? value) {
    _hintBuilder = value;
  }

  /// 设置错误文本构建器（null 表示不渲染错误文本）
  set errorBuilder(Widget Function(List<String>? list)? value) {
    _errorBuilder = value;
  }

  /// 设置边框与消息的布局策略
  set layout(WFormBorderLayout value) {
    _layout = value;
  }

  /// 构建 [WFormBorder] 组件
  WFormBorder build({
    List<String>? hintTextList,
    bool? isReadOnly,
    bool? isTransparentBackground,
    required Widget child,
  }) {
    return WFormBorder(
      config: this,
      hintTextList: hintTextList,
      isReadOnly: isReadOnly,
      isTransparentBackground: isTransparentBackground,
      child: child,
    );
  }

  /// 创建当前配置的副本
  WFormBorderConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示「保持原值」，无法通过 `copyWith(x: null)` 清空字段；
  /// 需要清空时请使用 setter，例如 `cfg.copy()..errorDecoration = null`。
  WFormBorderConfig copyWith({
    WFormBorderDecoration? defaultDecoration,
    WFormBorderDecoration? readOnlyDecoration,
    WFormBorderDecoration? errorDecoration,
    WFormBorderDecoration? focusedDecoration,
    Widget Function(List<String>? list)? hintBuilder,
    Widget Function(List<String>? list)? errorBuilder,
    WFormBorderLayout? layout,
  }) {
    final copyConfig = WFormBorderConfig();
    copyConfig._defaultDecoration = defaultDecoration ?? _defaultDecoration;
    copyConfig._readOnlyDecoration = readOnlyDecoration ?? _readOnlyDecoration;
    copyConfig._errorDecoration = errorDecoration ?? _errorDecoration;
    copyConfig._focusedDecoration = focusedDecoration ?? _focusedDecoration;
    copyConfig._hintBuilder = hintBuilder ?? _hintBuilder;
    copyConfig._errorBuilder = errorBuilder ?? _errorBuilder;
    copyConfig._layout = layout ?? _layout;
    return copyConfig;
  }
}

/// 表单边框装饰类，定义边框、背景色、圆角、阴影和渐变等样式
class WFormBorderDecoration {
  /// 边框（支持 `Border` 与 `BorderDirectional`）
  final BoxBorder? border;

  /// 背景颜色
  final Color? color;

  /// 边框圆角
  final BorderRadius? borderRadius;

  /// 阴影
  final List<BoxShadow>? boxShadow;

  /// 渐变
  final Gradient? gradient;

  /// 创建边框装饰
  const WFormBorderDecoration({
    this.border,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
  });

  /// 转换为 [BoxDecoration]
  BoxDecoration toBoxDecoration() {
    return BoxDecoration(
      border: border,
      color: color,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
    );
  }

  /// 创建当前装饰的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormBorderDecoration copyWith({
    BoxBorder? border,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return WFormBorderDecoration(
      border: border ?? this.border,
      color: color ?? this.color,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      gradient: gradient ?? this.gradient,
    );
  }
}

/// WFormBorderDecoration 扩展，提供链式调用方法
extension WFormBorderDecorationExtension on WFormBorderDecoration {
  /// 设置边框
  WFormBorderDecoration withBorder(BoxBorder border) {
    return copyWith(border: border);
  }

  /// 设置背景颜色
  WFormBorderDecoration withColor(Color color) {
    return copyWith(color: color);
  }

  /// 设置边框圆角
  WFormBorderDecoration withBorderRadius(BorderRadius borderRadius) {
    return copyWith(borderRadius: borderRadius);
  }

  /// 设置阴影
  WFormBorderDecoration withBoxShadow(List<BoxShadow> boxShadow) {
    return copyWith(boxShadow: boxShadow);
  }

  /// 设置渐变
  WFormBorderDecoration withGradient(Gradient gradient) {
    return copyWith(gradient: gradient);
  }

  /// 设置统一的边框宽度和颜色
  WFormBorderDecoration withUniformBorder(double width, Color color) {
    return copyWith(
      border: Border.all(width: width, color: color),
    );
  }

  /// 设置统一的边框圆角
  WFormBorderDecoration withUniformBorderRadius(double radius) {
    return copyWith(borderRadius: BorderRadius.all(Radius.circular(radius)));
  }
}
