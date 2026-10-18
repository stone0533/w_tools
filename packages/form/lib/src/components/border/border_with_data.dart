import 'package:flutter/material.dart';

import '../form_builder.dart';
import 'border.dart';
import 'read_only_scope.dart';

/// Row 扩展，为 Row 附加表单边框（[WFormBorderWithData]）及内部只读下发能力
extension WFormRowBorderExtension on Row {
  /// 为 Row 添加表单边框装饰，并把内部输入组件统一为只读 / 可编辑
  ///
  /// 同时作为错误展示的唯一出口：内部字段的错误由 [WFormBorder] 渲染。
  ///
  /// [name] 为边框注册键（需全局唯一）：单字段场景应与内部输入组件的 `name`
  /// 一致，否则校验红框无法自动联动；复合容器场景可取其组名，此时需手动
  /// `setError(组名)` 驱动边框错误态。
  ///
  /// [readOnly] 通过 [WFormReadOnlyScope] 下发给内部所有表单输入组件，
  /// 可穿透 `Padding` / `Center` / 自定义组件等任意包装。
  Widget withFormBorder({
    required String name,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool readOnly = false,
    bool enableFocusBorder = true,
    bool useIntrinsicHeight = false,
    Key? key,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      useIntrinsicHeight: useIntrinsicHeight,
      child: this,
    );
  }
}

/// 自动从祖先 [WFormBuilder] 获取表单数据、并复用同一个边框 key 的 WFormBorder
///
/// 同时负责：
/// - 通过 [WFormReadOnlyScope] 向内部下发只读状态；
/// - 聚焦追踪（[enableFocusBorder]）与可选 [IntrinsicHeight]；
/// - 作为错误展示的唯一出口：校验错误通过 `WFormData.setError` 设置 /
///   清除后由 [WFormBorder] 渲染，内部字段不再重复展示。
class WFormBorderWithData extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 边框注册键（用于 formBorderKeys 注册与 setError 定位，需全局唯一）
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

  /// 是否使用 IntrinsicHeight 包裹子组件
  final bool useIntrinsicHeight;

  /// 创建带表单数据的边框
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

/// WFormBorderWithData 的状态类
class _WFormBorderWithDataState extends State<WFormBorderWithData> {
  /// 当前是否聚焦
  bool _isFocused = false;

  void _onFocusChange(bool hasFocus) {
    if (!mounted) return;
    setState(() {
      _isFocused = hasFocus;
    });
  }

  @override
  void didUpdateWidget(WFormBorderWithData oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 关闭焦点边框后回调不再触发，需在此复位，避免边框卡在聚焦装饰
    if (!widget.enableFocusBorder && _isFocused) {
      _isFocused = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = WFormBuilder.requireOf(context);

    // 继承外层只读作用域：内层无法解除外层的只读锁定
    final isReadOnly = widget.readOnly || WFormReadOnlyScope.readOnlyOf(context);

    Widget child = widget.child;
    if (widget.enableFocusBorder) {
      child = Focus(onFocusChange: _onFocusChange, child: child);
    }
    if (widget.useIntrinsicHeight) {
      child = IntrinsicHeight(child: child);
    }
    // 始终插入作用域（值驱动），避免只读开关切换时重建整棵子树、丢失输入状态
    child = WFormReadOnlyScope(readOnly: isReadOnly, child: child);

    return WFormBorder(
      key: formData.ensureBorderKey(widget.name),
      config: WFormBuilder.borderConfigOf(context),
      hintTextList: widget.hintTextList,
      isReadOnly: isReadOnly,
      isTransparentBackground: widget.isTransparentBackground,
      isFocused: widget.enableFocusBorder ? _isFocused : null,
      child: child,
    );
  }
}
