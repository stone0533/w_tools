import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';

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
  /// [style] 为 null 时不渲染装饰；由 `WFormFieldShell` 传入生效样式。
  const WFormBorder({
    super.key,
    this.style,
    required this.child,
    this.hintTextList,
    this.isReadOnly,
    this.isTransparentBackground,
    this.isFocused,
    this.errorChannel,
    this.fieldErrorText,
    this.rendersInlineError = true,
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

  /// 边框配置（为 null 时不渲染装饰）
  final WFormBorderStyle? style;

  /// 错误通道：非 null 时显示为错误态，list 交给 `errorBuilder` 渲染
  final ValueListenable<List<String>?>? errorChannel;

  /// 字段自身的内联错误（`FormFieldState.errorText`）
  ///
  /// [rendersInlineError] 为 true 时说明错误已由输入控件（InputDecoration）渲染，
  /// 边框不再重复展示文案，只保留错误态装饰——这就是「两套错误通道」的消重规则。
  /// 为 false 时（checkbox / radio / date / multi / button），边框负责把文案渲染出来。
  final String? fieldErrorText;

  /// 字段自身是否会渲染 [fieldErrorText]。
  ///
  /// text / dropdown 走 InputDecoration，传 true；其余直接字段没有内联错误位置，
  /// 传 false 让边框兜底，避免原生 `validate()` 的错误文案被静默丢弃。
  final bool rendersInlineError;

  @override
  State<WFormBorder> createState() => WFormBorderState();
}

/// WFormBorder 的状态类
class WFormBorderState extends State<WFormBorder> {
  /// 当前生效的边框配置（显式传入或默认空配置）
  late WFormBorderStyle style;

  /// 是否有错误
  bool get isError => _isError;
  bool _isError = false;

  /// 消息列表（提示或错误）
  List<String>? get messageList => _messageList;
  List<String>? _messageList;

  /// 装饰缓存键（null 表示尚未计算）
  ///
  /// 用 record 承载全部判定条件，减少字段数量，并让「透明态装饰为 null」也能命中缓存。
  ({bool? transparent, bool? readOnly, bool isError, bool? focused})? _decorationKey;

  /// 本帧是否存在内联错误（由输入控件渲染）
  bool _hasInlineError = false;

  /// 本帧需要由边框兜底渲染的字段原生错误（字段自身不渲染 errorText 时）
  String? _externalErrorText;

  /// 缓存的装饰对象
  BoxDecoration? _cachedDecoration;

  /// 缓存的 BoxDecoration 对象
  BoxDecoration? _cachedBoxDecoration;

  /// 缓存的边框圆角
  BorderRadius? _cachedBorderRadius;

  /// 配置是否已同步过（首次同步必须执行）
  bool _styleReady = false;

  /// 未注入外部通道时自建的通道（`setError` 与内部测试用）
  ValueNotifier<List<String>?>? _ownChannel;

  /// 当前使用的错误通道
  late ValueListenable<List<String>?> _channel;

  /// 设置错误状态（包内使用；普通页面走 `WFormController.setError`）
  ///
  /// 无状态变化时直接返回，避免校验通过时对已无错误的字段重复触发重建。
  void setError(bool value, {List<String>? errorTextList}) {
    final next = value ? (errorTextList ?? const <String>[]) : null;
    if (next == null && !_isError) return;
    final channel = _channel;
    if (channel is ValueNotifier<List<String>?>) {
      channel.value = next;
    }
  }

  /// 错误通道变化：同步错误态与消息列表
  void _onErrorChanged() {
    final List<String>? error = _channel.value;
    if ((error != null) == _isError && listEquals(error, _messageList)) return;
    setState(() {
      _isError = error != null;
      _messageList = error ?? widget.hintTextList;
    });
  }

  @override
  void initState() {
    super.initState();
    // initState 中不能读取 InheritedWidget：先用显式配置或空配置占位，
    // 样式在 initState / didUpdateWidget 中同步
    style = widget.style ?? const WFormBorderStyle();
    _styleReady = true;
    _ownChannel = widget.errorChannel == null ? ValueNotifier<List<String>?>(null) : null;
    _channel = widget.errorChannel ?? _ownChannel!;
    final List<String>? error = _channel.value;
    _isError = error != null;
    _messageList = error ?? widget.hintTextList;
    _channel.addListener(_onErrorChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStyle();
  }

  @override
  void didUpdateWidget(WFormBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorChannel != widget.errorChannel) {
      _channel.removeListener(_onErrorChanged);
      _ownChannel?.dispose();
      _ownChannel = widget.errorChannel == null ? ValueNotifier<List<String>?>(null) : null;
      _channel = widget.errorChannel ?? _ownChannel!;
      _channel.addListener(_onErrorChanged);
      _onErrorChanged();
    }
    _syncStyle();
    // 非错误态下同步父级传入的新提示文本
    if (!_isError && !listEquals(widget.hintTextList, oldWidget.hintTextList)) {
      _messageList = widget.hintTextList;
    }
  }

  @override
  void dispose() {
    _channel.removeListener(_onErrorChanged);
    _ownChannel?.dispose();
    super.dispose();
  }

  /// 同步生效配置：显式传入优先，否则用空配置（不渲染装饰）。
  ///
  /// 用 `==`（值比较）而不是快照：内置工厂不再产生闭包，值相等的配置不会触发重建。
  void _syncStyle() {
    final resolved = widget.style ?? const WFormBorderStyle();
    if (_styleReady && resolved == style) return;
    style = resolved;
    _styleReady = true;
    _decorationKey = null; // 失效装饰缓存
  }

  /// 默认文案：`Text(list.join('；'))`，样式为空表示该配置不展示文案。
  Widget _defaultMessage(List<String> list, TextStyle? style) {
    if (style == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(list.join('；'), style: style),
    );
  }

  /// 获取当前状态对应的装饰（带缓存，状态未变时复用上次结果）
  BoxDecoration? _getDecoration() {
    final key = (
      transparent: widget.isTransparentBackground,
      readOnly: widget.isReadOnly,
      isError: _isError || _hasInlineError || _externalErrorText != null,
      focused: widget.isFocused,
    );

    if (key == _decorationKey) {
      return _cachedDecoration;
    }
    _decorationKey = key;

    BoxDecoration? decoration;
    if (key.isError) {
      // 错误态优先于透明背景：校验反馈不应因背景透明而丢失
      decoration = style.errorDecoration ?? style.defaultDecoration;
    } else if (widget.isTransparentBackground == true) {
      decoration = null;
    } else if (widget.isReadOnly == true) {
      decoration = style.readOnlyDecoration ?? style.defaultDecoration;
    } else if (widget.isFocused == true) {
      decoration = style.focusedDecoration ?? style.defaultDecoration;
    } else {
      decoration = style.defaultDecoration;
    }

    _cachedDecoration = decoration;
    _cachedBoxDecoration = decoration;
    final radius = decoration?.borderRadius;
    // ClipRRect 只接受 BorderRadius；Directional 圆角不参与裁剪，但装饰仍然生效。
    _cachedBorderRadius = radius is BorderRadius ? radius : null;

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
    // 内联错误必须在计算装饰前确定：它同时影响装饰与消息去重。
    // 字段不渲染 errorText 时（checkbox / radio / date / multi / button），
    // 由边框兜底展示，不能让原生 validate() 的文案静默消失。
    _hasInlineError = widget.rendersInlineError && widget.fieldErrorText != null;
    _externalErrorText = widget.rendersInlineError ? null : widget.fieldErrorText;
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
    //
    // 内联错误（由输入控件渲染）优先：同一字段只出现一次错误文案。
    final List<String>? externalErrorList = _externalErrorText == null
        ? null
        : <String>[_externalErrorText!];
    final List<String>? channelErrorList = _isError ? _messageList : null;
    final List<String>? errorList = _hasInlineError
        ? null
        : ((channelErrorList?.isNotEmpty ?? false) ? channelErrorList : externalErrorList);
    final bool hasMessage = _hasInlineError
        ? false
        : (errorList?.isNotEmpty ?? (_messageList?.isNotEmpty ?? false));
    final Widget message;
    if (!hasMessage) {
      message = const SizedBox.shrink();
    } else if (errorList != null) {
      message = style.errorBuilder?.call(errorList) ?? _defaultMessage(errorList, style.errorStyle);
    } else {
      message =
          style.hintBuilder?.call(_messageList) ??
          _defaultMessage(messageList!, style.effectiveHelperStyle);
    }

    // 3. 组装：边框在上，消息在下（固定布局）
    return columnBorderLayout(
      context,
      WFormBorderLayoutData(
        child: child,
        message: message,
        hasMessage: hasMessage,
        isError: _isError || _hasInlineError || _externalErrorText != null,
        isReadOnly: widget.isReadOnly ?? false,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// 表单边框配置类，定义边框的样式和构建器。
///
/// 本类为不可变配置；修改实例用 copyWith。
class WFormBorderStyle {
  final BoxDecoration? defaultDecoration;
  final BoxDecoration? readOnlyDecoration;
  final BoxDecoration? errorDecoration;
  final BoxDecoration? focusedDecoration;

  /// helper / error 文案的默认文字样式。
  ///
  /// [hintBuilder] / [errorBuilder] 为空时用它渲染 `Text(list.join('；'))`。
  /// 内置工厂（[WFormBorderStyle.standard] / [WFormBorderStyle.fromTheme]）走这两个字段
  /// 而不是闭包，因此配置之间可以做 `==` 比较（避免每帧重建）。
  final TextStyle? helperStyle;

  /// 历史名；用 [helperStyle]。构造参数已弃用（remove-in: 9.0.0）。
  final TextStyle? hintStyle;

  final TextStyle? errorStyle;

  /// 兼容新旧字段的实际 helper 文案样式。
  TextStyle? get effectiveHelperStyle => helperStyle ?? hintStyle;

  final Widget Function(List<String>? list)? hintBuilder;
  final Widget Function(List<String>? list)? errorBuilder;

  const WFormBorderStyle({
    this.defaultDecoration,
    this.readOnlyDecoration,
    this.errorDecoration,
    this.focusedDecoration,
    this.helperStyle,
    // remove-in: 9.0.0
    @Deprecated('Use helperStyle instead. remove-in: 9.0.0') this.hintStyle,
    this.errorStyle,
    this.hintBuilder,
    this.errorBuilder,
  });

  /// 显式浅色预设（历史入口）。
  ///
  /// 颜色写死，不跟随深色主题；新代码请用 [WFormBorderStyle.fromTheme]。
  factory WFormBorderStyle.standard({
    Color backgroundColor = Colors.white, // style-literal-ok: 显式浅色预设
    Color borderColor = const Color(0xFFE5E7EB), // style-literal-ok: 显式浅色预设
    Color focusColor = const Color(0xFF10B981), // style-literal-ok: 显式浅色预设
    Color errorColor = const Color(0xFFEF4444), // style-literal-ok: 显式浅色预设
    Color readOnlyColor = const Color(0xFFF9FAFB), // style-literal-ok: 显式浅色预设
    double radius = 12,
    TextStyle? helperStyle,
    // remove-in: 9.0.0
    @Deprecated('Use helperStyle instead. remove-in: 9.0.0') TextStyle? hintStyle,
    TextStyle? errorStyle,
  }) {
    final base = BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(radius),
    );
    final hintTextStyle =
        helperStyle ??
        hintStyle ??
        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)); // style-literal-ok: 显式浅色预设
    final errorTextStyle = errorStyle ?? TextStyle(fontSize: 12, color: errorColor);

    return WFormBorderStyle(
      defaultDecoration: base,
      focusedDecoration: base.copyWith(
        border: Border.all(color: focusColor, width: 1.5),
      ),
      errorDecoration: base.copyWith(
        border: Border.all(color: errorColor),
      ),
      readOnlyDecoration: base.copyWith(color: readOnlyColor),
      helperStyle: hintTextStyle,
      errorStyle: errorTextStyle,
    );
  }

  /// 从当前主题派生（推荐）：颜色全部来自 [ColorScheme]，跟随明暗与品牌色。
  ///
  /// 与 [standard] 的区别：边框 / 背景 / 聚焦 / 错误 / 只读底色都取自主题，
  /// hint / error 文字取 [TextTheme.bodySmall] 并分别用 `onSurfaceVariant` / `error`。
  ///
  /// ```dart
  /// WForm(
  ///   controller: form,
  ///   borderStyle: WFormBorderStyle.fromTheme(Theme.of(context)),
  ///   child: ...,
  /// )
  /// ```
  factory WFormBorderStyle.fromTheme(
    ThemeData theme, {
    double radius = 12,
    TextStyle? helperStyle,
    // remove-in: 9.0.0
    @Deprecated('Use helperStyle instead. remove-in: 9.0.0') TextStyle? hintStyle,
    TextStyle? errorStyle,
  }) {
    final scheme = theme.colorScheme;
    final base = BoxDecoration(
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(radius),
    );
    final hintTextStyle =
        (helperStyle ?? hintStyle ?? theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: (helperStyle ?? hintStyle)?.color ?? scheme.onSurfaceVariant,
        );
    final errorTextStyle = (errorStyle ?? theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: errorStyle?.color ?? scheme.error,
    );

    return WFormBorderStyle(
      defaultDecoration: base,
      focusedDecoration: base.copyWith(
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      errorDecoration: base.copyWith(
        border: Border.all(color: scheme.error),
      ),
      readOnlyDecoration: base.copyWith(color: scheme.surfaceContainerLow),
      helperStyle: hintTextStyle,
      errorStyle: errorTextStyle,
    );
  }

  WFormBorderStyle copyWith({
    BoxDecoration? defaultDecoration,
    BoxDecoration? readOnlyDecoration,
    BoxDecoration? errorDecoration,
    BoxDecoration? focusedDecoration,
    TextStyle? helperStyle,
    // remove-in: 9.0.0
    @Deprecated('Use helperStyle instead. remove-in: 9.0.0') TextStyle? hintStyle,
    TextStyle? errorStyle,
    Widget Function(List<String>? list)? hintBuilder,
    Widget Function(List<String>? list)? errorBuilder,
  }) {
    return WFormBorderStyle(
      defaultDecoration: defaultDecoration ?? this.defaultDecoration,
      readOnlyDecoration: readOnlyDecoration ?? this.readOnlyDecoration,
      errorDecoration: errorDecoration ?? this.errorDecoration,
      focusedDecoration: focusedDecoration ?? this.focusedDecoration,
      helperStyle: helperStyle ?? hintStyle ?? effectiveHelperStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      hintBuilder: hintBuilder ?? this.hintBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WFormBorderStyle &&
      other.defaultDecoration == defaultDecoration &&
      other.readOnlyDecoration == readOnlyDecoration &&
      other.errorDecoration == errorDecoration &&
      other.focusedDecoration == focusedDecoration &&
      other.helperStyle == helperStyle &&
      other.hintStyle == hintStyle &&
      other.errorStyle == errorStyle &&
      other.hintBuilder == hintBuilder &&
      other.errorBuilder == errorBuilder;

  @override
  int get hashCode => Object.hash(
    defaultDecoration,
    readOnlyDecoration,
    errorDecoration,
    focusedDecoration,
    helperStyle,
    hintStyle,
    errorStyle,
    hintBuilder,
    errorBuilder,
  );
}
