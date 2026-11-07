import 'package:flutter/material.dart';

import '../form_scope.dart';
import '../form_controller.dart';
import 'border.dart';
import 'read_only_scope.dart';

class WFormFieldShell extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 边框错误通道的键（用于 `WFormController.setError` 定位，需在同一表单内唯一）
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
      _formData?.unregisterBorder(widget.name, owner: this);
      _formData?.removeFormEntered(widget.name);
      _formData = next;
      _formData!.registerBorder(widget.name, owner: this);
    }
  }

  @override
  void dispose() {
    _formData?.unregisterBorder(widget.name, owner: this);
    _formData?.removeFormEntered(widget.name);
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

    // name 变化后旧 key 不再有意义，避免 formBorderKeys 累积
    if (oldWidget.name != widget.name) {
      _formData?.unregisterBorder(oldWidget.name, owner: this);
      _formData?.removeFormEntered(oldWidget.name);
      _formData?.registerBorder(widget.name, owner: this);
    }

    // 关闭焦点边框后回调不再触发，需在此复位，避免边框卡在聚焦装饰
    if (!widget.enableFocusBorder && _isFocused) {
      _isFocused = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      errorChannel: formData.errorChannelOf(widget.name),
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
