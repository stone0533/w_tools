import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/border_with_data.dart';
import '../border/read_only_scope.dart';
import '../form_builder.dart';
import '../form_data.dart';
import '../form_defaults.dart';

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

  /// 宿主表单数据（在 [didChangeDependencies] 中跟随 WFormBuilder 更新）
  late WFormData _formData;

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
    // 跟随 WFormBuilder 的 formData 实例变化，避免持有旧实例
    _formData = WFormBuilder.requireOf(context);
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

  /// 清空当前字段值（通过 [WFormData.didChange] 同步清空并广播给所有订阅者）
  ///
  /// 只读状态下不执行任何操作。
  void _clearField() {
    if (_effectiveReadOnly) return;
    _formData.didChange<String?>(widget.name, null);
  }

  @override
  Widget build(BuildContext context) {
    // 值变化回调：同步 ValueNotifier + FormData + 用户回调
    void onChanged(String? value) {
      _valueNotifier.value = value;
      _formData.onChange(widget.name, value);
      widget.onChanged?.call(value);
    }

    // 继承外层只读作用域（WFormBorderWithData.readOnly）
    _effectiveReadOnly = widget.readOnly || WFormReadOnlyScope.readOnlyOf(context);
    final readOnly = _effectiveReadOnly;

    final row = Row(
      children: [
        widget.config._leading ?? const SizedBox.shrink(),
        Expanded(
          child: Container(
            transform: widget.config._yOffset != null
                ? Matrix4.translationValues(0, widget.config._yOffset!, 0)
                : null,
            child: FormBuilderTextField(
              focusNode: _focusNode,
              name: widget.name,
              initialValue: widget.initialValue,
              validator: widget.validator,
              textInputAction: widget.config._textInputAction,
              readOnly: readOnly,
              onChanged: onChanged,
              cursorColor: widget.config._style?.color,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.config._hintStyle,
                fillColor: Colors.transparent,
                filled: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: widget.config._contentPadding,
                prefix: widget.config._prefix,
                prefixIcon: widget.config._prefixIcon,
                isCollapsed: true,
              ),
              style: readOnly
                  ? widget.config._readOnlyStyle ?? widget.config._style
                  : widget.config._style,
              strutStyle: StrutStyle(
                fontFamily: widget.config._style?.fontFamily,
                fontSize: widget.config._style?.fontSize,
                fontWeight: widget.config._style?.fontWeight,
                height: widget.config._style?.height,
                forceStrutHeight: true,
              ),
              obscureText: widget.config._obscureText && !_isPasswordVisible,
              obscuringCharacter: '＊',
              keyboardType:
                  widget.config._keyboardType ??
                  (widget.config._obscureText ? TextInputType.visiblePassword : null),
              inputFormatters: widget.config._inputFormatters,
              textAlign: widget.config._textAlign ?? TextAlign.start,
              autofocus: widget.config._autofocus ?? false,
              autocorrect: false,
              maxLines: widget.config._maxLines ?? 1,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
            ),
          ),
        ),
        ...?widget.config._actions,
      ],
    );

    return WFormTextFieldScope._(
      state: this,
      isPasswordVisible: _isPasswordVisible,
      readOnly: readOnly,
      child: Container(
        height: widget.config._height,
        width: widget.config._width,
        alignment: Alignment.center,
        decoration: widget.config._containerDecoration,
        margin: widget.config._containerMargin,
        padding: widget.config._containerPadding,
        child: row,
      ),
    );
  }
}

/// 文本输入配置类，定义文本输入的样式和行为
class WFormTextFieldConfig {
  /// 键盘类型
  TextInputType? _keyboardType;

  /// 输入格式化器
  List<TextInputFormatter>? _inputFormatters;

  /// 只读状态文本样式
  TextStyle? _readOnlyStyle;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// 文本样式
  TextStyle? _style;

  /// 内容内边距
  EdgeInsetsGeometry? _contentPadding;

  /// 提示文本样式
  TextStyle? _hintStyle;

  /// Y 轴偏移
  double? _yOffset;

  /// 左侧组件
  Widget? _leading;

  /// 操作按钮列表
  List<Widget>? _actions;

  /// 容器装饰
  Decoration? _containerDecoration;

  /// 容器边距
  EdgeInsetsGeometry? _containerMargin;

  /// 容器内边距
  EdgeInsetsGeometry? _containerPadding;

  /// 文本对齐方式
  TextAlign? _textAlign;

  /// 是否自动获取焦点
  bool? _autofocus;

  /// 是否密码模式
  bool _obscureText = false;

  /// 前缀组件
  Widget? _prefix;

  /// 前缀图标
  Widget? _prefixIcon;

  /// 最大行数
  int? _maxLines;

  /// 文本输入动作
  TextInputAction? _textInputAction;

  /// 设置键盘类型
  set keyboardType(TextInputType? value) {
    _keyboardType = value;
  }

  /// 设置输入格式化器
  set inputFormatters(List<TextInputFormatter>? value) {
    _inputFormatters = value;
  }

  /// 设置只读状态文本样式
  set readOnlyStyle(TextStyle? value) {
    _readOnlyStyle = value;
  }

  /// 设置高度
  set height(double? value) {
    _height = value;
  }

  /// 设置宽度
  set width(double? value) {
    _width = value;
  }

  /// 设置文本样式
  set style(TextStyle? value) {
    _style = value;
  }

  /// 设置内容内边距
  set contentPadding(EdgeInsetsGeometry? value) {
    _contentPadding = value;
  }

  /// 设置提示文本样式
  set hintStyle(TextStyle? value) {
    _hintStyle = value;
  }

  /// 设置 Y 轴偏移
  set yOffset(double? value) {
    _yOffset = value;
  }

  /// 设置左侧组件
  set leading(Widget? value) {
    _leading = value;
  }

  /// 设置操作按钮列表
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 设置容器装饰
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 设置容器边距
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 设置容器内边距
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
  }

  /// 设置文本对齐方式
  set textAlign(TextAlign? value) {
    _textAlign = value;
  }

  /// 设置是否自动获取焦点
  set autofocus(bool? value) {
    _autofocus = value;
  }

  /// 设置是否密码模式
  set obscureText(bool value) {
    _obscureText = value;
  }

  /// 设置前缀组件
  set prefix(Widget? value) {
    _prefix = value;
  }

  /// 设置前缀图标
  set prefixIcon(Widget? value) {
    _prefixIcon = value;
  }

  /// 设置最大行数
  set maxLines(int? value) {
    _maxLines = value;
  }

  /// 设置文本输入动作
  set textInputAction(TextInputAction? value) {
    _textInputAction = value;
  }

  /// 构建 [WFormTextField] 组件
  WFormTextField build({
    required String name,
    ValueChanged<String?>? onChanged,
    void Function(String?)? onSubmitted,
    VoidCallback? onEditingComplete,
    String? initialValue,
    String? hintText,
    bool readOnly = false,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
  }) {
    return WFormTextField(
      config: this,
      name: name,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      initialValue: initialValue,
      hintText: hintText,
      readOnly: readOnly,
      validator: validator,
      focusNode: focusNode,
    );
  }

  /// 创建当前配置的副本
  WFormTextFieldConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormTextFieldConfig copyWith({
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
    final config = WFormTextFieldConfig();
    config._keyboardType = keyboardType ?? _keyboardType;
    config._inputFormatters = inputFormatters ?? _inputFormatters;
    config._readOnlyStyle = readOnlyStyle ?? _readOnlyStyle;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._style = style ?? _style;
    config._contentPadding = contentPadding ?? _contentPadding;
    config._hintStyle = hintStyle ?? _hintStyle;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._textAlign = textAlign ?? _textAlign;
    config._autofocus = autofocus ?? _autofocus;
    config._obscureText = obscureText ?? _obscureText;
    config._prefix = prefix ?? _prefix;
    config._prefixIcon = prefixIcon ?? _prefixIcon;
    config._maxLines = maxLines ?? _maxLines;
    config._textInputAction = textInputAction ?? _textInputAction;
    return config;
  }

  /// 构建带有 [WFormBorderWithData] 包装的 [WFormTextField] 组件
  ///
  /// 内层容器装饰会被清空，边框交由外层绘制。
  Widget buildBordered({
    required String name,
    ValueChanged<String?>? onChanged,
    void Function(String?)? onSubmitted,
    VoidCallback? onEditingComplete,
    String? initialValue,
    String? hintText,
    bool readOnly = false,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }

    // 清空内层容器装饰（在副本上操作，避免污染原配置的后续 build()），边框交由外层 WFormBorder 绘制
    final innerConfig = copy()..containerDecoration = null;

    final textField = innerConfig.build(
      name: name,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      initialValue: initialValue,
      hintText: hintText,
      readOnly: readOnly,
      validator: validator,
      focusNode: focusNode,
    );

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      child: textField,
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
  bool get obscureText => _state.widget.config._obscureText;
}

/// 表单文本框 action 的通用实现
///
/// 封装了「取状态 → 订阅值变化 → 条件显示 → 点击处理」这套样板，
/// 调用方只需描述图标与点击行为：
///
/// ```dart
/// WFormTextFieldAction(
///   visibleWhen: (data) => data.hasText,
///   iconBuilder: (data) => Icon(data.hasText ? Icons.send : Icons.send_outlined),
///   onPressed: (data) => submit(data.value!),
/// )
/// ```
class WFormTextFieldAction extends StatelessWidget {
  /// 图标构建器（可读取当前状态，动态决定图标）
  final Widget Function(WFormTextFieldData data) iconBuilder;

  /// 点击回调（可读取当前状态）；为 null 时不可点击
  final void Function(WFormTextFieldData data)? onPressed;

  /// 是否显示（默认始终显示），随输入值变化重新求值
  final bool Function(WFormTextFieldData data)? visibleWhen;

  const WFormTextFieldAction({
    super.key,
    required this.iconBuilder,
    this.onPressed,
    this.visibleWhen,
  });

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldScope.of(context);
    if (data == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: data.valueListenable,
      builder: (context, _) {
        if (!(visibleWhen?.call(data) ?? true)) {
          return const SizedBox.shrink();
        }

        final icon = iconBuilder(data);
        if (onPressed == null) return icon;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onPressed!(data),
            behavior: HitTestBehavior.opaque,
            child: icon,
          ),
        );
      },
    );
  }
}

/// 密码可见/隐藏切换按钮（预置 action）
///
/// 放入 [WFormTextFieldConfig.actions] 列表即可。图标从
/// [WFormDefaults.obscureTextIcon] / [WFormDefaults.obscureTextVisibleIcon] 取全局默认。
///
/// ```dart
/// WFormTextField(
///   config: WFormTextFieldConfig()
///     ..obscureText = true
///     ..actions = const [WFormTextFieldPasswordToggle()],
///   name: 'password',
/// )
/// ```
class WFormTextFieldPasswordToggle extends StatelessWidget {
  const WFormTextFieldPasswordToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.obscureText,
      iconBuilder: (data) => data.isPasswordVisible
          ? WFormDefaults.obscureTextVisibleIcon
          : WFormDefaults.obscureTextIcon,
      onPressed: (data) => data.togglePasswordVisibility(),
    );
  }
}

/// 清空文本按钮（预置 action）
///
/// 仅当文本框有内容且非只读时可见。点击清空字段值，并回调 [onCleared]。
/// 内部订阅 [WFormTextFieldData.valueListenable]，无需额外状态管理。
class WFormTextFieldClearButton extends StatelessWidget {
  /// 点击清空后的额外回调
  ///
  /// 仅按钮点击触发；通过 `data.clear()` 等编程式方式清空不会触发。
  final VoidCallback? onCleared;

  /// 自定义图标，默认取 [WFormDefaults.clearButtonIcon]
  ///
  /// 点击热区与图标的渲染尺寸一致；需要更大热区请传入更大的图标，
  /// 或用 SizedBox 包裹图标来扩大点击区域。
  final Widget? icon;

  const WFormTextFieldClearButton({
    super.key,
    this.onCleared,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.hasText && !data.readOnly,
      iconBuilder: (_) => icon ?? WFormDefaults.clearButtonIcon,
      onPressed: (data) {
        data.clear();
        onCleared?.call();
      },
    );
  }
}
