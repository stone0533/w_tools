import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'form_builder.dart';
import 'border.dart';
import '../../config.dart';

/// 表单单行文本输入组件
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

  /// 焦点节点
  final FocusNode? focusNode;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 文本输入配置
  /// @param name 字段名称
  /// @param onChanged 值变化回调
  /// @param onSubmitted 提交回调
  /// @param onEditingComplete 编辑完成回调
  /// @param initialValue 初始值
  /// @param hintText 提示文本
  /// @param readOnly 是否只读
  /// @param focusNode 焦点节点
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
    this.focusNode,
  });

  @override
  State<WFormTextField> createState() => _WFormTextFieldState();
}

/// WFormTextField 的状态类
class _WFormTextFieldState extends State<WFormTextField> {
  /// 是否显示密码
  bool _isPasswordVisible = false;
  
  /// 焦点节点
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // 如果用户提供了焦点节点，使用用户提供的，否则创建一个新的
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    // 如果焦点节点是我们自己创建的，需要手动销毁
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
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

    // 定义值变化回调函数
    void onChangedHandler(String? value) {
      // 确保 wFormData 不为 null
      if (wFormData != null) {
        wFormData.onChange(widget.name, value);
      }
      // 调用用户传入的回调函数
      widget.onChanged?.call(value);
    }

    // 切换密码显示状态
    void togglePasswordVisibility() {
      setState(() {
        _isPasswordVisible = !_isPasswordVisible;
      });
    }

    // 构建密码显示/隐藏图标
    Widget? obscureTextIcon;
    if (widget.config._obscureText) {
      // 密码模式下使用配置的显示/隐藏图标或默认图标
      final icon = _isPasswordVisible
          ? (widget.config._obscureTextIconOn ?? WConfig.instance.obscureTextIconOn)
          : (widget.config._obscureTextIcon ?? WConfig.instance.obscureTextIcon);
      
      obscureTextIcon = GestureDetector(
        onTap: togglePasswordVisibility,
        child: Container(
          padding: EdgeInsets.zero,
          child: icon,
        ),
      );
    }

    return Container(
      height: widget.config._height,
      alignment: Alignment.center,
      decoration: widget.config._containerDecoration,
      margin: widget.config._containerMargin,
      padding: widget.config._containerPadding,
      child: Row(
        children: [
          widget.config._leading ?? Container(),
          Expanded(
            child: Container(
              transform: widget.config._yOffset != null
                  ? Matrix4.translationValues(0, widget.config._yOffset!, 0)
                  : null,
              child: FormBuilderTextField(
                focusNode: _focusNode,
                name: widget.name,
                initialValue: widget.initialValue,
                textInputAction: widget.config._textInputAction,
                readOnly: widget.readOnly,
                onChanged: onChangedHandler,
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
                  suffixIconConstraints: BoxConstraints(maxHeight: 20.w),
                  suffixIcon: obscureTextIcon,
                  isCollapsed: true,
                ),
                style: widget.readOnly
                    ? widget.config._readOnlyStyle ?? widget.config._style
                    : widget.config._style,
                strutStyle: StrutStyle(
                  fontFamily: widget.config._style?.fontFamily,
                  fontSize: widget.config._style?.fontSize,
                  // leading: 0.5,
                  //forceStrutHeight: true,
                  height: widget.config._style?.height,
                ),
                obscureText: widget.config._obscureText && !_isPasswordVisible,
                obscuringCharacter: '＊',
                keyboardType: widget.config._keyboardType ?? (widget.config._obscureText ? TextInputType.visiblePassword : null),
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
          ...?widget.config._actions?.map(
            (action) => Container(
              height: widget.config._height,
              alignment: Alignment.center,
              child: action,
            ),
          ),
        ],
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

  /// 文本样式
  TextStyle? _style;

  /// 内容内边距
  EdgeInsetsGeometry? _contentPadding;

  /// 提示文本样式
  TextStyle? _hintStyle;

  /// Y轴偏移
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

  /// 密码显示/隐藏图标
  Widget? _obscureTextIcon;

  /// 激活状态密码显示/隐藏图标
  Widget? _obscureTextIconOn;

  /// 最大行数
  int? _maxLines;

  /// 文本输入动作
  TextInputAction? _textInputAction;

  /// 键盘类型 setter
  set keyboardType(TextInputType? value) {
    _keyboardType = value;
  }

  /// 输入格式化器 setter
  set inputFormatters(List<TextInputFormatter>? value) {
    _inputFormatters = value;
  }

  /// 只读状态文本样式 setter
  set readOnlyStyle(TextStyle? value) {
    _readOnlyStyle = value;
  }

  /// 高度 setter
  set height(double? value) {
    _height = value;
  }

  /// 文本样式 setter
  set style(TextStyle? value) {
    _style = value;
  }

  /// 内容内边距 setter
  set contentPadding(EdgeInsetsGeometry? value) {
    _contentPadding = value;
  }

  /// 提示文本样式 setter
  set hintStyle(TextStyle? value) {
    _hintStyle = value;
  }

  /// Y轴偏移 setter
  set yOffset(double? value) {
    _yOffset = value;
  }

  /// 左侧组件 setter
  set leading(Widget? value) {
    _leading = value;
  }

  /// 操作按钮列表 setter
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 容器装饰 setter
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 容器边距 setter
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 容器内边距 setter
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
  }

  /// 文本对齐方式 setter
  set textAlign(TextAlign? value) {
    _textAlign = value;
  }

  /// 自动获取焦点 setter
  set autofocus(bool? value) {
    _autofocus = value;
  }
  
  /// 是否密码模式 setter
  set obscureText(bool value) {
    _obscureText = value;
  }

  /// 前缀组件 setter
  set prefix(Widget? value) {
    _prefix = value;
  }

  /// 前缀图标 setter
  set prefixIcon(Widget? value) {
    _prefixIcon = value;
  }

  /// 密码显示/隐藏图标 setter
  set obscureTextIcon(Widget? value) {
    _obscureTextIcon = value;
  }

  /// 激活状态密码显示/隐藏图标 setter
  set obscureTextIconOn(Widget? value) {
    _obscureTextIconOn = value;
  }

  /// 最大行数 setter
  set maxLines(int? value) {
    _maxLines = value;
  }

  /// 文本输入动作 setter
  set textInputAction(TextInputAction? value) {
    _textInputAction = value;
  }

  /// 构建 WFormTextField 组件
  ///
  /// @param name 字段名称
  /// @param onChanged 值变化回调
  /// @param onSubmitted 提交回调
  /// @param onEditingComplete 编辑完成回调
  /// @param initialValue 初始值
  /// @param hintText 提示文本
  /// @param readOnly 是否只读
  /// @param focusNode 焦点节点
  /// @return WFormTextField 实例
  WFormTextField build({
    required String name,
    ValueChanged<String?>? onChanged,
    void Function(String?)? onSubmitted,
    VoidCallback? onEditingComplete,
    String? initialValue,
    String? hintText,
    bool readOnly = false,
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
      focusNode: focusNode,
    );
  }

  /// 复制当前配置，创建一个新的配置实例
  ///
  /// @return 新的 WFormTextFieldConfig 实例
  WFormTextFieldConfig copy() {
    final config = WFormTextFieldConfig();
    config._keyboardType = _keyboardType;
    config._inputFormatters = _inputFormatters;
    config._readOnlyStyle = _readOnlyStyle;
    config._height = _height;
    config._style = _style;
    config._contentPadding = _contentPadding;
    config._hintStyle = _hintStyle;
    config._yOffset = _yOffset;
    config._leading = _leading;
    config._actions = _actions;
    config._containerDecoration = _containerDecoration;
    config._containerMargin = _containerMargin;
    config._containerPadding = _containerPadding;
    config._textAlign = _textAlign;
    config._autofocus = _autofocus;
    config._obscureText = _obscureText;
    config._prefix = _prefix;
    config._prefixIcon = _prefixIcon;
    config._obscureTextIcon = _obscureTextIcon;
    config._obscureTextIconOn = _obscureTextIconOn;
    config._maxLines = _maxLines;
    config._textInputAction = _textInputAction;
    return config;
  }

  /// 构建带有 WFormBorder 包装的 WFormTextField 组件
  ///
  /// @param name 字段名称
  /// @param onChanged 值变化回调
  /// @param onSubmitted 提交回调
  /// @param onEditingComplete 编辑完成回调
  /// @param initialValue 初始值
  /// @param hintText 提示文本
  /// @param readOnly 是否只读
  /// @param focusNode 焦点节点
  /// @param hintTextList 提示文本列表
  /// @param isTransparentBackground 是否透明背景
  /// @param key 组件键
  /// @param enableFocusBorder 是否启用焦点边框
  /// @return 带有 WFormBorder 包装的 WFormTextField 实例
  Widget buildBordered({
    required String name,
    ValueChanged<String?>? onChanged,
    void Function(String?)? onSubmitted,
    VoidCallback? onEditingComplete,
    String? initialValue,
    String? hintText,
    bool readOnly = false,
    FocusNode? focusNode,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
  }) {
    // 验证 name 参数
    if (name.isEmpty) {
      throw Exception('字段名称不能为空');
    }
    
    containerDecoration = null;

    final textField = build(
      name: name,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      initialValue: initialValue,
      hintText: hintText,
      readOnly: readOnly,
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



