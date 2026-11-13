import 'package:flutter/material.dart';

import '../form_scope.dart';
import '../form_controller.dart';
import 'border.dart';
import 'border_access.dart';
import 'read_only_scope.dart';

/// 自定义字段的外框：注册错误通道、注入只读作用域并绘制边框。
///
/// 普通页面用直接字段（`WFormTextField` 等），不需要直接使用本类；
/// 需要接 `flutter_form_builder` 自定义字段时，用它包住字段以复用
/// 边框 / 错误 / 只读这一套能力。
class WFormFieldShell extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 字段名（用于 `WFormController.setError` 定位错误通道，需在同一表单内唯一）
  ///
  /// 单字段场景应与内部输入组件的 name 一致；复合容器场景可作为分组名。
  final String name;

  /// 提示文本列表
  final List<String>? hintTextList;

  /// 是否透明背景
  final bool? isTransparentBackground;

  /// 是否只读
  final bool readOnly;

  /// 是否启用焦点边框
  final bool enableFocusBorder;

  /// 创建带表单数据的边框
  const WFormFieldShell({
    super.key,
    required this.name,
    this.hintTextList,
    this.isTransparentBackground,
    required this.readOnly,
    this.enableFocusBorder = true,
    required this.child,
  });

  @override
  State<WFormFieldShell> createState() => _WFormFieldShellState();
}

/// WFormFieldShell 的状态类
class _WFormFieldShellState extends State<WFormFieldShell> {
  /// 当前是否聚焦
  bool _isFocused = false;

  /// 当前绑定的表单 controller（用于卸载时注销 border key）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = WFormScope.requireOf(context);
    if (!identical(_formData, next)) {
      final previous = _formData;
      if (previous != null) {
        bordersOf(previous).unregister(widget.name, owner: this);
      }
      _formData = next;
      bordersOf(next).register(widget.name, owner: this);
    }
  }

  @override
  void dispose() {
    final formData = _formData;
    if (formData != null) {
      bordersOf(formData).unregister(widget.name, owner: this);
    }
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    if (!mounted) return;
    setState(() {
      _isFocused = hasFocus;
    });
  }

  @override
  void didUpdateWidget(WFormFieldShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // name 变化后旧通道不再有意义，避免 registry 累积
    final formData = _formData;
    if (oldWidget.name != widget.name && formData != null) {
      bordersOf(formData).unregister(oldWidget.name, owner: this);
      bordersOf(formData).register(widget.name, owner: this);
    }

    // 关闭焦点边框后回调不再触发，需在此复位，避免边框卡在聚焦装饰
    if (!widget.enableFocusBorder && _isFocused) {
      _isFocused = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 依赖 Form 的 generation：原生 `formKey.validate()` 会写字段的
    // `errorText`，但不会 rebuild 本 Shell。没有这条依赖时，边框会继续用
    // 上一帧的 `fieldErrorText` 快照，导致和内联错误各渲染一条文案。
    Form.maybeOf(context);

    final formData = WFormScope.requireOf(context);

    // 继承外层只读作用域：内层无法解除外层的只读锁定
    final isReadOnly = widget.readOnly || WFormReadOnlyScope.readOnlyOf(context);

    Widget child = widget.child;
    if (widget.enableFocusBorder) {
      child = Focus(onFocusChange: _onFocusChange, child: child);
    }
    // 始终插入作用域（值驱动），避免只读开关切换时重建整棵子树、丢失输入状态
    child = WFormReadOnlyScope(readOnly: isReadOnly, child: child);

    return WFormBorder(
      errorChannel: bordersOf(formData).channelOf(widget.name),
      fieldErrorText: formData.fields?[widget.name]?.errorText,
      style: WFormScope.borderStyleOf(context),
      hintTextList: widget.hintTextList,
      isReadOnly: isReadOnly,
      isTransparentBackground: widget.isTransparentBackground,
      isFocused: widget.enableFocusBorder ? _isFocused : null,
      child: child,
    );
  }
}
