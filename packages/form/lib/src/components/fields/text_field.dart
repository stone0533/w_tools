import 'package:flutter/foundation.dart' show ValueListenable, internal;
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
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormTextFieldCore extends StatefulWidget {
  /// 输入装饰（hint / 前后缀 / 边框样式）
  final InputDecoration? decoration;

  /// hint 文字样式
  final TextStyle? hintStyle;

  /// 输入框内边距
  final EdgeInsetsGeometry? contentPadding;

  /// 前缀 widget
  final Widget? prefix;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 正文样式
  final TextStyle? style;

  /// 只读态正文样式
  final TextStyle? readOnlyStyle;

  /// 是否密码模式
  final bool obscureText;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 输入格式化器
  final List<TextInputFormatter>? inputFormatters;

  /// 文本对齐
  final TextAlign? textAlign;

  /// 是否自动聚焦
  final bool? autofocus;

  /// 最大行数
  final int? maxLines;

  /// 键盘动作
  final TextInputAction? textInputAction;

  /// 外框高度
  final double? height;

  /// 外框宽度
  final double? width;

  /// 内容 Y 轴偏移
  final double? yOffset;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 外框装饰（bordered 时由边框接管）
  final Decoration? containerDecoration;

  /// 外框外边距
  final EdgeInsetsGeometry? containerMargin;

  /// 外框内边距
  final EdgeInsetsGeometry? containerPadding;

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

  /// 是否启用（null 时读取 [enabled]）
  /// 是否启用（只读作用域仍会覆盖）
  final bool enabled;

  /// 校验器
  final FormFieldValidator<String>? validator;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 创建单行文本输入组件
  const WFormTextFieldCore({
    super.key,
    required this.name,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.initialValue,
    this.hintText,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.focusNode,
    this.decoration,
    this.hintStyle,
    this.contentPadding,
    this.prefix,
    this.prefixIcon,
    this.style,
    this.readOnlyStyle,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign,
    this.autofocus,
    this.maxLines,
    this.textInputAction,
    this.height,
    this.width,
    this.yOffset,
    this.leading,
    this.actions,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
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

    // 合并自身 enabled / enabled / 外层只读作用域
    final inheritedReadOnly = WFormReadOnlyScope.readOnlyOf(context);
    final isEnabled = widget.enabled && !inheritedReadOnly;
    _effectiveReadOnly = !isEnabled || widget.readOnly || inheritedReadOnly;
    final readOnly = _effectiveReadOnly;

    final customDecoration = widget.decoration;
    final hintText = widget.hintText ?? widget.hintText ?? customDecoration?.hintText;

    return WFormTextFieldScope._(
      state: this,
      isPasswordVisible: _isPasswordVisible,
      readOnly: readOnly,
      child: WFormFieldFrame(
        height: widget.height,
        width: widget.width,
        decoration: widget.containerDecoration,
        margin: widget.containerMargin,
        padding: widget.containerPadding,
        yOffset: widget.yOffset,
        leading: widget.leading,
        actions: widget.actions,
        child: FormBuilderTextField(
          focusNode: _focusNode,
          name: widget.name,
          initialValue: widget.initialValue,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          enabled: isEnabled,
          readOnly: readOnly,
          onChanged: onChanged,
          cursorColor: widget.style?.color,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: customDecoration?.hintStyle ?? widget.hintStyle,
            fillColor: customDecoration?.fillColor ?? Colors.transparent,
            filled: customDecoration?.filled ?? true,
            border: customDecoration?.border ?? InputBorder.none,
            enabledBorder: customDecoration?.enabledBorder ?? InputBorder.none,
            focusedBorder: customDecoration?.focusedBorder ?? InputBorder.none,
            errorBorder: customDecoration?.errorBorder ?? InputBorder.none,
            focusedErrorBorder: customDecoration?.focusedErrorBorder ?? InputBorder.none,
            contentPadding: customDecoration?.contentPadding ?? widget.contentPadding,
            prefix: customDecoration?.prefix ?? widget.prefix,
            prefixIcon: customDecoration?.prefixIcon ?? widget.prefixIcon,
            suffix: customDecoration?.suffix,
            suffixIcon: customDecoration?.suffixIcon,
            isCollapsed: customDecoration?.isCollapsed ?? true,
          ),
          style: readOnly ? widget.readOnlyStyle ?? widget.style : widget.style,
          strutStyle: StrutStyle(
            fontFamily: widget.style?.fontFamily,
            fontSize: widget.style?.fontSize,
            fontWeight: widget.style?.fontWeight,
            height: widget.style?.height,
            forceStrutHeight: true,
          ),
          obscureText: widget.obscureText && !_isPasswordVisible,
          obscuringCharacter: '＊',
          keyboardType:
              widget.keyboardType ?? (widget.obscureText ? TextInputType.visiblePassword : null),
          inputFormatters: widget.inputFormatters,
          textAlign: widget.textAlign ?? TextAlign.start,
          autofocus: widget.autofocus ?? false,
          autocorrect: false,
          maxLines: widget.maxLines ?? 1,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
        ),
      ),
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
/// 使用示例（需要跟随输入值重建时，必须订阅 [valueListenable]）：
/// ```dart
/// class MyCustomSearchAction extends StatelessWidget {
///   const MyCustomSearchAction({super.key});
///   @override
///   Widget build(BuildContext context) {
///     final data = WFormTextFieldScope.of(context);
///     if (data == null) return const SizedBox.shrink();
///     return ListenableBuilder(
///       listenable: data.valueListenable,
///       builder: (context, _) {
///         if (!data.hasText) return const SizedBox.shrink();
///         return IconButton(
///           icon: const Icon(Icons.search),
///           onPressed: () {/* ... */},
///         );
///       },
///     );
///   }
/// }
/// ```
///
/// 注意：`value` / `hasText` 本身**不会**让调用方重建（scope 只在密码可见性与只读变化时通知），
/// 所以在 `build` 里直接读它们会拿到旧值。预置的 [WFormTextFieldAction] /
/// [WFormTextFieldClearButton] 已内部订阅。
abstract interface class WFormTextFieldData {
  /// 当前密码是否可见（仅 `WFormTextField.obscureText` 为 true 时有意义）
  bool get isPasswordVisible;

  /// 是否为密码模式（对应 `WFormTextField.obscureText`）
  bool get obscureText;

  /// 当前输入值（null 表示未输入过）
  ///
  /// 读取本 getter 不会触发重建；要跟随输入变化请用 [valueListenable]。
  String? get value;

  /// 是否有输入内容（`value != null && value.isNotEmpty` 的快捷判断）
  ///
  /// 同样不触发重建；在 `build` 里用请包一层 [ListenableBuilder]。
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
  bool get obscureText => _state.widget.obscureText;
}
