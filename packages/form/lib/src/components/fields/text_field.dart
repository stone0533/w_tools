import 'package:flutter/foundation.dart' show ValueListenable, internal;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../field_base_config.dart';
import '../form_scope.dart';
import '../form_controller.dart';

/// 表单单行文本输入组件
///
/// 支持密码模式、输入格式化器、只读样式与 `actions` / `leading` 插槽；
/// 只读状态会合并自身 [readOnly] 与外层 [WFormReadOnlyScope]。
/// 插槽中的控件可通过 [WFormTextFieldScope.of] 读取输入状态并触发清空、
/// 密码可见性切换等操作。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormTextFieldCore extends StatefulWidget {
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
  const WFormTextFieldCore({
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
  State<WFormTextFieldCore> createState() => _WFormTextFieldState();
}

/// WFormTextFieldCore 的状态类
class _WFormTextFieldState extends State<WFormTextFieldCore> {
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
  void didUpdateWidget(WFormTextFieldCore oldWidget) {
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

    final customDecoration = widget.config.decoration;
    final hintText = widget.hintText ?? widget.config.hintText ?? customDecoration?.hintText;

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
            hintText: hintText,
            hintStyle: customDecoration?.hintStyle ?? widget.config.hintStyle,
            fillColor: customDecoration?.fillColor ?? Colors.transparent,
            filled: customDecoration?.filled ?? true,
            border: customDecoration?.border ?? InputBorder.none,
            enabledBorder: customDecoration?.enabledBorder ?? InputBorder.none,
            focusedBorder: customDecoration?.focusedBorder ?? InputBorder.none,
            errorBorder: customDecoration?.errorBorder ?? InputBorder.none,
            focusedErrorBorder: customDecoration?.focusedErrorBorder ?? InputBorder.none,
            contentPadding: customDecoration?.contentPadding ?? widget.config.contentPadding,
            prefix: customDecoration?.prefix ?? widget.config.prefix,
            prefixIcon: customDecoration?.prefixIcon ?? widget.config.prefixIcon,
            suffix: customDecoration?.suffix,
            suffixIcon: customDecoration?.suffixIcon,
            isCollapsed: customDecoration?.isCollapsed ?? true,
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
/// 本类为不可变配置；修改实例用 copyWith。
class WFormTextFieldConfig extends WFormFieldBaseConfig {
  TextInputType? keyboardType;
  List<TextInputFormatter>? inputFormatters;
  TextStyle? readOnlyStyle;
  TextStyle? style;
  EdgeInsetsGeometry? contentPadding;
  TextStyle? hintStyle;
  String? hintText;
  InputDecoration? decoration;
  TextAlign? textAlign;
  bool? autofocus;
  bool obscureText;
  Widget? prefix;
  Widget? prefixIcon;
  int? maxLines;
  TextInputAction? textInputAction;

  WFormTextFieldConfig({
    bool enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.readOnlyStyle,
    double? height,
    double? width,
    this.style,
    this.contentPadding,
    this.hintStyle,
    this.hintText,
    this.decoration,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    this.textAlign,
    this.autofocus,
    this.obscureText = false,
    this.prefix,
    this.prefixIcon,
    this.maxLines,
    this.textInputAction,
  }) {
    this.enabled = enabled;
    this.height = height;
    this.width = width;
    this.yOffset = yOffset;
    this.leading = leading;
    this.actions = actions;
    this.containerDecoration = containerDecoration;
    this.containerMargin = containerMargin;
    this.containerPadding = containerPadding;
  }

  /// 框架内部使用（直接字段 / Core 组装），4.0 物理移出 Config。
  @internal
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
    bool enableFocusBorder = true,
  }) {
    final config = bordered ? (copy()..containerDecoration = null) : this;
    final effectiveReadOnly = readOnly || !enabled;
    final field = WFormTextFieldCore(
      config: config,
      name: name,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      initialValue: initialValue,
      hintText: hintText ?? this.hintText,
      readOnly: readOnly,
      enabled: enabled,
      validator: validator,
      focusNode: focusNode,
    );
    if (!bordered) {
      // 与其它字段一致：无边框时也要下发只读作用域，消费方插槽才能读到
      if (effectiveReadOnly) {
        return WFormReadOnlyScope(readOnly: true, child: field);
      }
      // message / hintTextList 只由边框渲染；无边框时静默丢弃是陷阱，直接报出来
      assert(
        hintTextList == null || hintTextList.isEmpty,
        'bordered: false 时不会渲染 message / hintTextList；需要提示请保留 bordered，或自行展示。',
      );
      return field;
    }
    return WFormFieldFrame.border(
      name: name,
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
    String? hintText,
    InputDecoration? decoration,
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
      hintText: hintText ?? this.hintText,
      decoration: decoration ?? this.decoration,
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

// ---------------------------------------------------------------------------
// 插件化管道：公开接口 + InheritedWidget Scope + 预置 Widget
// ---------------------------------------------------------------------------

/// WFormTextFieldCore 暴露给 actions / leading 槽 Widget 的只读接口。
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

/// 承载 WFormTextFieldCore 内部状态的 InheritedWidget，实现 [WFormTextFieldData]。
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
  /// 未在 WFormTextFieldCore 子树中使用时返回 null，调用方需做 null 保护。
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
