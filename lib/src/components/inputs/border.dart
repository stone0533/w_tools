import 'package:flutter/material.dart';

import '../../../w.dart';

/// WFormBorder 组件是一个表单边框容器，用于为表单输入添加统一的边框样式和错误提示
///
/// 该组件支持以下特性：
/// - 可配置的边框样式（颜色、宽度、圆角）
/// - 支持只读状态和错误状态
/// - 支持透明背景
/// - 支持提示文本和错误文本
class WFormBorder extends StatefulWidget {
  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 边框配置
  /// @param child 子组件
  /// @param hintTextList 提示文本列表
  /// @param isReadOnly 是否只读
  /// @param isTransparentBackground 是否透明背景
  /// @param isFocused 是否聚焦
  /// @param tag 标签
  const WFormBorder({
    super.key,
    this.config,
    required this.child,
    this.hintTextList,
    this.isReadOnly,
    this.isTransparentBackground,
    this.isFocused,
    this.tag,
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

  /// 边框配置
  final WFormBorderConfig? config;

  /// 标签
  final String? tag;

  @override
  State<WFormBorder> createState() => WFormBorderState();
}

/// WFormBorder 的状态类
class WFormBorderState extends State<WFormBorder> {
  /// 边框配置
  late final WFormBorderConfig config;

  /// 是否有错误
  bool isError = false;

  /// 消息列表（提示或错误）
  List<String>? messageList;

  /// 缓存的装饰对象，用于避免重复计算
  WFormBorderDecoration? _cachedDecoration;

  /// 缓存的 BoxDecoration 对象，用于避免重复转换
  BoxDecoration? _cachedBoxDecoration;

  /// 缓存的边框圆角，用于避免重复获取
  BorderRadius? _cachedBorderRadius;

  /// 缓存的透明背景状态，用于检测状态变化
  bool? _cachedIsTransparentBackground;

  /// 缓存的只读状态，用于检测状态变化
  bool? _cachedIsReadOnly;

  /// 缓存的错误状态，用于检测状态变化
  bool? _cachedIsError;

  /// 缓存的聚焦状态，用于检测状态变化
  bool? _cachedIsFocused;

  /// 设置错误状态
  ///
  /// @param value 是否有错误
  /// @param errorTextList 错误文本列表
  void setError(bool value, {List<String>? errorTextList}) {
    if (isError != value) {
      setState(() {
        isError = value;
      });
    }
    setState(() {
      if (isError) {
        messageList = errorTextList;
      } else {
        messageList = widget.hintTextList;
      }
    });
  }

  @override
  void initState() {
    // 获取基础配置
    WFormBorderConfig baseConfig = widget.config ?? WFormBorderConfig();

    // 检查是否有 tag 并且配置中有 configForTagCallback
    if (widget.tag != null && baseConfig._configForTagCallback != null) {
      // 调用回调函数获取新的配置
      config = baseConfig._configForTagCallback!(widget.tag!, baseConfig.copy()) ?? baseConfig;
    } else {
      // 使用基础配置
      config = baseConfig;
    }

    messageList = widget.hintTextList;
    super.initState();
  }

  /// 获取装饰
  ///
  /// @return 装饰对象
  WFormBorderDecoration? _getDecoration() {
    // 检查状态是否变化
    final isStateChanged =
        _cachedIsTransparentBackground != widget.isTransparentBackground ||
        _cachedIsReadOnly != widget.isReadOnly ||
        _cachedIsError != isError ||
        _cachedIsFocused != widget.isFocused;

    if (!isStateChanged && _cachedDecoration != null) {
      return _cachedDecoration;
    }

    // 更新缓存的状态
    _cachedIsTransparentBackground = widget.isTransparentBackground;
    _cachedIsReadOnly = widget.isReadOnly;
    _cachedIsError = isError;
    _cachedIsFocused = widget.isFocused;

    WFormBorderDecoration? decoration;
    if (widget.isTransparentBackground == true) {
      decoration = null;
    } else if (isError) {
      decoration = config._errorDecoration ?? config._defaultDecoration;
    } else if (widget.isReadOnly == true) {
      decoration = config._readOnlyDecoration ?? config._defaultDecoration;
    } else if (widget.isFocused == true) {
      decoration = config._focusedDecoration ?? config._defaultDecoration;
    } else {
      decoration = config._defaultDecoration;
    }

    // 更新缓存
    _cachedDecoration = decoration;
    _cachedBoxDecoration = decoration?.toBoxDecoration();
    _cachedBorderRadius = decoration?.borderRadius;

    return decoration;
  }

  /// 获取 BoxDecoration
  ///
  /// @return BoxDecoration 对象
  BoxDecoration? _getBoxDecoration() {
    // 确保装饰对象已缓存
    _getDecoration();
    return _cachedBoxDecoration;
  }

  /// 获取边框圆角
  ///
  /// @return 边框圆角
  BorderRadius? _getBorderRadius() {
    // 确保装饰对象已缓存
    _getDecoration();
    return _cachedBorderRadius;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = _getBorderRadius();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: _getBoxDecoration(),
          child: borderRadius != null
              ? ClipRRect(
                  borderRadius: borderRadius,
                  child: widget.child,
                )
              : widget.child,
        ),
        Builder(
          builder: (_) {
            if (messageList?.isEmpty ?? true) {
              return Container();
            }
            if (isError == true) {
              return config._errorBuilder.call(messageList);
            }
            return config._hintBuilder.call(messageList);
          },
        ),
      ],
    );
  }
}

/// 表单边框配置类，定义边框的样式和构建器
class WFormBorderConfig {
  /// 默认状态的装饰
  WFormBorderDecoration? _defaultDecoration;

  /// 只读状态的装饰
  WFormBorderDecoration? _readOnlyDecoration;

  /// 错误状态的装饰
  WFormBorderDecoration? _errorDecoration;

  /// 聚焦状态的装饰
  WFormBorderDecoration? _focusedDecoration;

  /// 提示文本构建器
  late Function(List<String>? list) _hintBuilder;

  /// 错误文本构建器
  late Function(List<String>? list) _errorBuilder;

  /// 标签配置回调函数
  /// 返回一个 WFormBorderConfig
  WFormBorderConfig? Function(String tag, WFormBorderConfig currentConfig)? _configForTagCallback;

  /// 构造函数，设置默认值
  WFormBorderConfig() {
    /*
    /// 设置默认装饰
    _defaultDecoration = WFormBorderDecoration(
      border: Border.all(width: 1.w, color: HexColor.fromHex('#EAEAEA')),
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(20.w)),
    );

    /// 设置只读状态装饰
    _readOnlyDecoration = WFormBorderDecoration(
      border: Border.all(width: 1.w, color: HexColor.fromHex('#EAEAEA')),
      color: HexColor.fromHex('#F5F5F5'),
      borderRadius: BorderRadius.all(Radius.circular(20.w)),
    );

    /// 设置错误状态装饰
    _errorDecoration = WFormBorderDecoration(
      border: Border.all(width: 1.w, color: HexColor.fromHex('#C0061A')),
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(20.w)),
    );

    /// 设置聚焦状态装饰
    _focusedDecoration = WFormBorderDecoration(
      border: Border.all(width: 1.w, color: Colors.blue),
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(20.w)),
    );

    /// 设置提示文本构建器
    _hintBuilder = (list) => Container(
      padding: EdgeInsets.symmetric(vertical: 4.w),
      child: Wrap(
        runSpacing: 2.w,
        children: [
          ...?list?.map((a) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    a,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                      color: HexColor.fromHex('#3F3F3F'),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );

    /// 设置错误文本构建器
    _errorBuilder = (list) => Container(
      padding: EdgeInsets.symmetric(vertical: 4.w),
      child: Wrap(
        runSpacing: 2.w,
        children: [
          ...?list?.map((a) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    a,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                      color: HexColor.fromHex('#C0061A'),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
    */
  }

  /// 默认状态装饰 setter
  set defaultDecoration(WFormBorderDecoration? value) {
    _defaultDecoration = value;
  }

  /// 只读状态装饰 setter
  set readOnlyDecoration(WFormBorderDecoration? value) {
    _readOnlyDecoration = value;
  }

  /// 错误状态装饰 setter
  set errorDecoration(WFormBorderDecoration? value) {
    _errorDecoration = value;
  }

  /// 聚焦状态装饰 setter
  set focusedDecoration(WFormBorderDecoration? value) {
    _focusedDecoration = value;
  }

  /// 提示文本构建器 setter
  set hintBuilder(Function(List<String>? list) value) {
    _hintBuilder = value;
  }

  /// 错误文本构建器 setter
  set errorBuilder(Function(List<String>? list) value) {
    _errorBuilder = value;
  }

  /// 标签配置回调函数 setter
  set configForTagCallback(
    WFormBorderConfig? Function(String tag, WFormBorderConfig currentConfig) value,
  ) {
    _configForTagCallback = value;
  }

  /// 构建 WFormBorder 组件
  ///
  /// @param hintTextList 提示文本列表
  /// @param isReadOnly 是否只读
  /// @param isTransparentBackground 是否透明背景
  /// @param child 子组件
  /// @return WFormBorder 实例
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

  /// 复制当前配置，返回一个新的 WFormBorderConfig 实例
  ///
  /// @return 新的 WFormBorderConfig 实例
  WFormBorderConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param defaultDecoration 默认状态的装饰
  /// @param readOnlyDecoration 只读状态的装饰
  /// @param errorDecoration 错误状态的装饰
  /// @param focusedDecoration 聚焦状态的装饰
  /// @param hintBuilder 提示文本构建器
  /// @param errorBuilder 错误文本构建器
  /// @param configForTagCallback 标签配置回调函数
  /// @return WFormBorderConfig 实例，包含更新后的配置
  WFormBorderConfig copyWith({
    WFormBorderDecoration? defaultDecoration,
    WFormBorderDecoration? readOnlyDecoration,
    WFormBorderDecoration? errorDecoration,
    WFormBorderDecoration? focusedDecoration,
    Function(List<String>? list)? hintBuilder,
    Function(List<String>? list)? errorBuilder,
    WFormBorderConfig? Function(String tag, WFormBorderConfig currentConfig)? configForTagCallback,
  }) {
    final copyConfig = WFormBorderConfig();
    copyConfig._defaultDecoration = defaultDecoration ?? _defaultDecoration;
    copyConfig._readOnlyDecoration = readOnlyDecoration ?? _readOnlyDecoration;
    copyConfig._errorDecoration = errorDecoration ?? _errorDecoration;
    copyConfig._focusedDecoration = focusedDecoration ?? _focusedDecoration;
    copyConfig._hintBuilder = hintBuilder ?? _hintBuilder;
    copyConfig._errorBuilder = errorBuilder ?? _errorBuilder;
    copyConfig._configForTagCallback = configForTagCallback ?? _configForTagCallback;
    return copyConfig;
  }
}

class WFormBorderDecoration {
  /// 边框
  final Border? border;

  /// 背景颜色
  final Color? color;

  /// 边框圆角
  final BorderRadius? borderRadius;

  /// 阴影
  final List<BoxShadow>? boxShadow;

  /// 渐变
  final Gradient? gradient;

  /// 构造函数
  const WFormBorderDecoration({
    this.border,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
  });

  /// 转换为 BoxDecoration
  BoxDecoration toBoxDecoration() {
    return BoxDecoration(
      border: border,
      color: color,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
    );
  }

  /// 复制并修改属性
  WFormBorderDecoration copyWith({
    Border? border,
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
  WFormBorderDecoration withBorder(Border border) {
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

/// 辅助方法，用于递归处理 widget 树，设置 readOnly 属性
Widget _processWidgetTree(Widget widget, bool readOnly) {
  // 检查 widget 是否有 readOnly 属性
  if (widget is WFormTextField) {
    return WFormTextField(
      name: widget.name,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      hintText: widget.hintText,
      config: widget.config,
      readOnly: readOnly,
      focusNode: widget.focusNode,
    );
  }

  // 处理 WFormDropdown 组件
  if (widget is WFormDropdown) {
    return WFormDropdown(
      config: widget.config,
      name: widget.name,
      items: widget.items,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      hint: widget.hint,
      hintText: widget.hintText,
      enabled: !readOnly,
      width: widget.width,
    );
  }

  // 处理其他可能有 readOnly 属性的 widget
  // 这里可以根据需要添加其他类型的 widget

  // 处理包含子 widget 的容器
  if (widget is Container) {
    return Container(
      key: widget.key,
      alignment: widget.alignment,
      padding: widget.padding,
      margin: widget.margin,
      color: widget.color,
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
      width: widget.constraints?.maxWidth,
      height: widget.constraints?.maxHeight,
      constraints: widget.constraints,
      child: widget.child != null ? _processWidgetTree(widget.child!, readOnly) : null,
    );
  }

  if (widget is Row) {
    return Row(
      key: widget.key,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      textBaseline: widget.textBaseline,
      children: widget.children.map((child) => _processWidgetTree(child, readOnly)).toList(),
    );
  }

  if (widget is Column) {
    return Column(
      key: widget.key,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      textBaseline: widget.textBaseline,
      children: widget.children.map((child) => _processWidgetTree(child, readOnly)).toList(),
    );
  }

  if (widget is Stack) {
    return Stack(
      key: widget.key,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      children: widget.children.map((child) => _processWidgetTree(child, readOnly)).toList(),
    );
  }

  if (widget is Wrap) {
    return Wrap(
      key: widget.key,
      direction: widget.direction,
      alignment: widget.alignment,
      spacing: widget.spacing,
      runAlignment: widget.runAlignment,
      runSpacing: widget.runSpacing,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      children: widget.children.map((child) => _processWidgetTree(child, readOnly)).toList(),
    );
  }

  if (widget is Expanded) {
    return Expanded(
      key: widget.key,
      flex: widget.flex,
      child: _processWidgetTree(widget.child, readOnly),
    );
  }

  if (widget is Flexible) {
    return Flexible(
      key: widget.key,
      flex: widget.flex,
      fit: widget.fit,
      child: _processWidgetTree(widget.child, readOnly),
    );
  }

  // 处理 SizedBox 组件
  if (widget is SizedBox) {
    return SizedBox(
      key: widget.key,
      width: widget.width,
      height: widget.height,
      child: widget.child != null ? _processWidgetTree(widget.child!, readOnly) : null,
    );
  }

  // 如果没有匹配的 widget 类型，返回原始 widget
  return widget;
}

/// Row 扩展，提供 buildBordered 方法
extension RowBorderedExtension on Row {
  /// 为 Row 添加边框装饰
  ///
  /// @param name 字段名称
  /// @param hintTextList 提示文本列表
  /// @param isTransparentBackground 是否透明背景
  /// @param readOnly 是否只读
  /// @param enableFocusBorder 是否启用焦点边框
  /// @param useIntrinsicHeight 是否使用 IntrinsicHeight 包裹子组件
  /// @param key 组件键
  /// @return 带边框的 Row 组件
  Widget buildBordered({
    required String name,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool readOnly = false,
    bool enableFocusBorder = true,
    bool useIntrinsicHeight = false,
    Key? key,
  }) {
    // 验证 name 参数
    if (name.isEmpty) {
      throw Exception('字段名称不能为空');
    }

    // 处理 Row 内部的 widget，设置 readOnly 属性
    final processedRow = _processWidgetTree(this, readOnly);

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      useIntrinsicHeight: useIntrinsicHeight,
      child: processedRow,
    );
  }
}

/// 带 WFormData 自动获取的 WFormBorder
class WFormBorderWithData extends StatefulWidget {
  final Widget child;
  final String name;
  final List<String>? hintTextList;
  final bool? isTransparentBackground;
  final bool readOnly;
  final bool enableFocusBorder;
  final bool useIntrinsicHeight;

  const WFormBorderWithData({
    super.key,
    required this.name,
    this.hintTextList,
    this.isTransparentBackground,
    required this.readOnly,
    this.enableFocusBorder = true,
    this.useIntrinsicHeight = false,
    required this.child,
  });

  @override
  State<WFormBorderWithData> createState() => _WFormBorderWithDataState();
}

class _WFormBorderWithDataState extends State<WFormBorderWithData> {
  /// 当前是否聚焦
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
  }

  /// 焦点变化回调
  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取 WFormData 实例
    dynamic wFormData = WFormBuilder.of(context);

    if (wFormData == null) {
      // 尝试遍历祖先元素，查找 WFormBuilder 实例
      context.visitAncestorElements((element) {
        if (element.widget is WFormBuilder) {
          wFormData = (element.widget as WFormBuilder).formData;
          return false; // 停止遍历
        }
        return true; // 继续遍历
      });
    }

    if (wFormData == null) {
      throw Exception('WFormBuilder 未找到');
    }

    Widget child = Focus(
      onFocusChange: widget.enableFocusBorder ? _onFocusChange : null,
      child: widget.child,
    );

    if (widget.useIntrinsicHeight) {
      child = IntrinsicHeight(child: child);
    }

    return WFormBorder(
      key: wFormData.getFormBorderKey(widget.name),
      config: wFormData.formBorderConfig,
      hintTextList: widget.hintTextList,
      isReadOnly: widget.readOnly,
      isTransparentBackground: widget.isTransparentBackground,
      isFocused: _isFocused,
      child: child,
    );
  }
}
