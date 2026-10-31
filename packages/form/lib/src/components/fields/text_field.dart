import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_controller.dart';

/// 表单单行文本输入组件
///
/// 支持密码模式、输入格式化器、只读样式与 `actions` / `leading` 插槽；
/// 只读状态会合并自身 [readOnly] 与外层 [WFormReadOnlyScope]。
/// 插槽中的控件可通过 [WFormTextFieldScope.of] 读取输入状态并触发清空、
/// 密码可见性切换等操作。
class WFormTextField extends StatefulWidget {
  /// 文本输入配置
  final WFormTextFieldConfig config;

  /// 字段名称
  final String name;

  /// 值变化回调
  final ValueChanged<String?>? onChanged;

  /// 提交回调
  final void Function(String?)? onSubmitted;

  /// 编辑完成回调
  final VoidCallback? onEditingComplete;

  /// 初始值
  final String? initialValue;

  /// 提示文本
  final String? hintText;

  /// 是否只读
  final bool readOnly;

  /// 是否启用（null 时读取 [config.enabled]）
  final bool? enabled;

  /// 校验器
  final FormFieldValidator<String>? validator;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 创建单行文本输入组件
  const WFormTextField({
    super.key,
    required this.config,
    required this.name,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.initialValue,
    this.hintText,
    this.readOnly = false,
    this.enabled,
    this.validator,
    this.focusNode,
  });

  @override
  State<WFormTextField> createState() => _WFormTextFieldState();
}

/// WFormTextField 的状态类
class _WFormTextFieldState extends State<WFormTextField> {
  /// 密码是否可见（仅 obscureText=true 时有效）
  bool _isPasswordVisible = false;

  /// 焦点节点
  late FocusNode _focusNode;

  /// 当前输入值的订阅器（供 actions Widget 监听 hasText / clear）
  final ValueNotifier<String?> _valueNotifier = ValueNotifier<String?>(null);

  /// 宿主表单数据（在 [didChangeDependencies] 中跟随 WFormScope 更新）
  late WFormController _formData;

  /// 当前生效的只读状态（组件自身 + 外层只读作用域）
  bool _effectiveReadOnly = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    if (widget.initialValue != null) {
      _valueNotifier.value = widget.initialValue;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 跟随 WFormScope 的 formData 实例变化，避免持有旧实例
    _formData = WFormScope.requireOf(context);
  }

  @override
  void didUpdateWidget(WFormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.initialValue != oldWidget.initialValue) {
      _valueNotifier.value = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _formData.removeFormEntered(widget.name);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _valueNotifier.dispose();
    super.dispose();
  }

  /// 切换密码可见状态
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  /// 清空当前字段值（通过 [WFormController.setValue] 同步清空并广播给所有订阅者）
  ///
  /// 只读状态下不执行任何操作。
  void _clearField() {
    if (_effectiveReadOnly) return;
    _formData.setValue<String?>(widget.name, null);
  }

  @override
  Widget build(BuildContext context) {
    // 值变化回调：同步 ValueNotifier + FormData + 用户回调
    void onChanged(String? value) {
      _valueNotifier.value = value;
      _formData.handleChange(widget.name, value);
      widget.onChanged?.call(value);
    }

    // 合并自身 enabled / config.enabled / 外层只读作用域
    final inheritedReadOnly = WFormReadOnlyScope.readOnlyOf(context);
    final isEnabled = (widget.enabled ?? widget.config.enabled) && !inheritedReadOnly;
    _effectiveReadOnly = !isEnabled || widget.readOnly || inheritedReadOnly;
    final readOnly = _effectiveReadOnly;

    return WFormTextFieldScope._(
      state: this,
      isPasswordVisible: _isPasswordVisible,
      readOnly: readOnly,
      child: WFormFieldFrame(
        height: widget.config.height,
        width: widget.config.width,
        decoration: widget.config.containerDecoration,
        margin: widget.config.containerMargin,
        padding: widget.config.containerPadding,
        yOffset: widget.config.yOffset,
        leading: widget.config.leading,
        actions: widget.config.actions,
        child: FormBuilderTextField(
          focusNode: _focusNode,
          name: widget.name,
          initialValue: widget.initialValue,
          validator: widget.validator,
          textInputAction: widget.config.textInputAction,
          enabled: isEnabled,
          readOnly: readOnly,
          onChanged: onChanged,
          cursorColor: widget.config.style?.color,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.config.hintStyle,
            fillColor: Colors.transparent,
            filled: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: widget.config.contentPadding,
            prefix: widget.config.prefix,
            prefixIcon: widget.config.prefixIcon,
            isCollapsed: true,
          ),
          style: readOnly
              ? widget.config.readOnlyStyle ?? widget.config.style
              : widget.config.style,
          strutStyle: StrutStyle(
            fontFamily: widget.config.style?.fontFamily,
            fontSize: widget.config.style?.fontSize,
            fontWeight: widget.config.style?.fontWeight,
            height: widget.config.style?.height,
            forceStrutHeight: true,
          ),
          obscureText: widget.config.obscureText && !_isPasswordVisible,
          obscuringCharacter: '＊',
          keyboardType:
              widget.config.keyboardType ??
              (widget.config.obscureText ? TextInputType.visiblePassword : null),
          inputFormatters: widget.config.inputFormatters,
          textAlign: widget.config.textAlign ?? TextAlign.start,
          autofocus: widget.config.autofocus ?? false,
          autocorrect: false,
          maxLines: widget.config.maxLines ?? 1,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
        ),
      ),
    );
  }
}

/// 文本输入配置类，定义文本输入的样式和行为。
///
/// 本类已迁移为不可变配置；需要链式构建时使用 [builder]。
class WFormTextFieldConfig {
  static WFormTextFieldConfigBuilder builder() => WFormTextFieldConfigBuilder();

  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? readOnlyStyle;
  final double? height;
  final double? width;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final double? yOffset;
  final Widget? leading;
  final List<Widget>? actions;
  final Decoration? containerDecoration;
  final EdgeInsetsGeometry? containerMargin;
  final EdgeInsetsGeometry? containerPadding;
  final TextAlign? textAlign;
  final bool? autofocus;
  final bool obscureText;
  final Widget? prefix;
  final Widget? prefixIcon;
  final int? maxLines;
  final TextInputAction? textInputAction;

  const WFormTextFieldConfig({
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.readOnlyStyle,
    this.height,
    this.width,
    this.style,
    this.contentPadding,
    this.hintStyle,
    this.yOffset,
    this.leading,
    this.actions,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
    this.textAlign,
    this.autofocus,
    this.obscureText = false,
    this.prefix,
    this.prefixIcon,
    this.maxLines,
    this.textInputAction,
  });

  Widget build({
    required String name,
    ValueChanged<String?>? onChanged,
    void Function(String?)? onSubmitted,
    VoidCallback? onEditingComplete,
    String? initialValue,
    String? hintText,
    bool readOnly = false,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    bool bordered = false,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? borderKey,
    bool enableFocusBorder = true,
  }) {
    final config = bordered
        ? (WFormTextFieldConfigBuilder.from(this)..containerDecoration = null).buildConfig()
        : this;
    final effectiveReadOnly = readOnly || !enabled;
    final field = WFormTextField(
      config: config,
      name: name,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      initialValue: initialValue,
      hintText: hintText,
      readOnly: readOnly,
      enabled: enabled,
      validator: validator,
      focusNode: focusNode,
    );
    if (!bordered) {
      return field;
    }
    return WFormFieldFrame.border(
      name: name,
      borderKey: borderKey,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      enableFocusBorder: enableFocusBorder,
      readOnly: effectiveReadOnly,
      child: field,
    );
  }

  WFormTextFieldConfig copy() => copyWith();

  WFormTextFieldConfig copyWith({
    bool? enabled,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextStyle? readOnlyStyle,
    double? height,
    double? width,
    TextStyle? style,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? hintStyle,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    TextAlign? textAlign,
    bool? autofocus,
    bool? obscureText,
    Widget? prefix,
    Widget? prefixIcon,
    int? maxLines,
    TextInputAction? textInputAction,
  }) {
    return WFormTextFieldConfig(
      enabled: enabled ?? this.enabled,
      keyboardType: keyboardType ?? this.keyboardType,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      readOnlyStyle: readOnlyStyle ?? this.readOnlyStyle,
      height: height ?? this.height,
      width: width ?? this.width,
      style: style ?? this.style,
      contentPadding: contentPadding ?? this.contentPadding,
      hintStyle: hintStyle ?? this.hintStyle,
      yOffset: yOffset ?? this.yOffset,
      leading: leading ?? this.leading,
      actions: actions ?? this.actions,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
      textAlign: textAlign ?? this.textAlign,
      autofocus: autofocus ?? this.autofocus,
      obscureText: obscureText ?? this.obscureText,
      prefix: prefix ?? this.prefix,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      maxLines: maxLines ?? this.maxLines,
      textInputAction: textInputAction ?? this.textInputAction,
    );
  }
}

/// [WFormTextFieldConfig] 的 Builder，最后通过 [buildConfig] 产出不可变配置。
class WFormTextFieldConfigBuilder {
  bool enabled = true;
  TextInputType? keyboardType;
  List<TextInputFormatter>? inputFormatters;
  TextStyle? readOnlyStyle;
  double? height;
  double? width;
  TextStyle? style;
  EdgeInsetsGeometry? contentPadding;
  TextStyle? hintStyle;
  double? yOffset;
  Widget? leading;
  List<Widget>? actions;
  Decoration? containerDecoration;
  EdgeInsetsGeometry? containerMargin;
  EdgeInsetsGeometry? containerPadding;
  TextAlign? textAlign;
  bool? autofocus;
  bool obscureText = false;
  Widget? prefix;
  Widget? prefixIcon;
  int? maxLines;
  TextInputAction? textInputAction;

  WFormTextFieldConfigBuilder();

  WFormTextFieldConfigBuilder.from(WFormTextFieldConfig config)
    : enabled = config.enabled,
      keyboardType = config.keyboardType,
      inputFormatters = config.inputFormatters,
      readOnlyStyle = config.readOnlyStyle,
      height = config.height,
      width = config.width,
      style = config.style,
      contentPadding = config.contentPadding,
      hintStyle = config.hintStyle,
      yOffset = config.yOffset,
      leading = config.leading,
      actions = config.actions,
      containerDecoration = config.containerDecoration,
      containerMargin = config.containerMargin,
      containerPadding = config.containerPadding,
      textAlign = config.textAlign,
      autofocus = config.autofocus,
      obscureText = config.obscureText,
      prefix = config.prefix,
      prefixIcon = config.prefixIcon,
      maxLines = config.maxLines,
      textInputAction = config.textInputAction;

  WFormTextFieldConfig buildConfig() {
    return WFormTextFieldConfig(
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnlyStyle: readOnlyStyle,
      height: height,
      width: width,
      style: style,
      contentPadding: contentPadding,
      hintStyle: hintStyle,
      yOffset: yOffset,
      leading: leading,
      actions: actions,
      containerDecoration: containerDecoration,
      containerMargin: containerMargin,
      containerPadding: containerPadding,
      textAlign: textAlign,
      autofocus: autofocus,
      obscureText: obscureText,
      prefix: prefix,
      prefixIcon: prefixIcon,
      maxLines: maxLines,
      textInputAction: textInputAction,
    );
  }
}

// ---------------------------------------------------------------------------
// 插件化管道：公开接口 + InheritedWidget Scope + 预置 Widget
// ---------------------------------------------------------------------------

/// WFormTextField 暴露给 actions / leading 槽 Widget 的只读接口。
///
/// 用户自定义 action Widget 通过 [WFormTextFieldScope.of] 获取此接口，
/// 读取输入状态、订阅值变化、触发密码切换或清空等动作，无需闭包或外部回调。
///
/// 使用示例：
/// ```dart
/// class MyCustomSearchAction extends StatelessWidget {
///   const MyCustomSearchAction({super.key});
///   @override
///   Widget build(BuildContext context) {
///     final data = WFormTextFieldScope.of(context);
///     if (data == null || !data.hasText) return const SizedBox.shrink();
///     return IconButton(
///       icon: const Icon(Icons.search),
///       onPressed: () {/* ... */},
///     );
///   }
/// }
/// ```
abstract final class WFormTextFieldData {
  /// 当前密码是否可见（仅 [WFormTextFieldConfig.obscureText] 为 true 时有意义）
  bool get isPasswordVisible;

  /// 是否为密码模式（对应 [WFormTextFieldConfig.obscureText]）
  bool get obscureText;

  /// 当前输入值（null 表示未输入过）
  String? get value;

  /// 是否有输入内容（`value != null && value.isNotEmpty` 的快捷判断）
  bool get hasText;

  /// 字段是否只读（含外层只读作用域）
  bool get readOnly;

  /// 订阅值变化的监听器（供 actions Widget 做值驱动的重建）
  ValueListenable<String?> get valueListenable;

  /// 切换密码可见状态
  void togglePasswordVisibility();

  /// 清空当前字段值
  void clear();
}

/// 承载 WFormTextField 内部状态的 InheritedWidget，实现 [WFormTextFieldData]。
///
/// widget 树中任意位置的 Widget 可通过 [WFormTextFieldScope.of] 获取接口实例。
final class WFormTextFieldScope extends InheritedWidget implements WFormTextFieldData {
  /// 宿主 State（内部实现委托）
  final _WFormTextFieldState _state;

  @override
  final bool isPasswordVisible;

  @override
  final bool readOnly;

  const WFormTextFieldScope._({
    required _WFormTextFieldState state,
    required this.isPasswordVisible,
    required this.readOnly,
    required super.child,
  }) : _state = state;

  /// 从 context 向上查找最近的 WFormTextFieldScope，返回 [WFormTextFieldData] 接口。
  ///
  /// 未在 WFormTextField 子树中使用时返回 null，调用方需做 null 保护。
  static WFormTextFieldData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WFormTextFieldScope>();
  }

  @override
  bool updateShouldNotify(WFormTextFieldScope oldWidget) {
    return oldWidget.isPasswordVisible != isPasswordVisible || oldWidget.readOnly != readOnly;
  }

  // --- WFormTextFieldData 接口实现（全部委托给 _state）---

  @override
  String? get value => _state._valueNotifier.value;

  @override
  bool get hasText => (_state._valueNotifier.value ?? '').isNotEmpty;

  @override
  ValueListenable<String?> get valueListenable => _state._valueNotifier;

  @override
  void togglePasswordVisibility() => _state._togglePasswordVisibility();

  @override
  void clear() => _state._clearField();

  @override
  bool get obscureText => _state.widget.config.obscureText;
}
