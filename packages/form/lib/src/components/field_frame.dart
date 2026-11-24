import 'package:flutter/material.dart';

import 'border/field_shell.dart';

/// 表单字段的布局外框（内部实现，不对外导出）
///
/// 统一此前在 7 个字段里各自复制的结构：
///
/// ```
/// Container(height/width/decoration/margin/padding)
///   └── Row[leading, Expanded(Container(yOffset 位移, child)), ...actions]
/// ```
///
/// 以及 bordered 构建路径的公共装配：
/// 空 name 校验 + `WFormFieldShell` 包装（内层装饰由调用方清空）。
///
/// 字段之间的语义差异（text 的 `readOnly`、其他字段的 `enabled`）仍由各字段
/// 自行计算后传入，不进入本类的接口。
class WFormFieldFrame extends StatelessWidget {
  /// 创建字段外框
  const WFormFieldFrame({
    super.key,
    required this.child,
    this.height,
    this.heightIsMinimum = false,
    this.width,
    this.decoration,
    this.margin,
    this.padding,
    this.yOffset,
    this.leading,
    this.actions,
  });

  /// 字段内部控件（输入框 / 下拉 / 复选框内容等）
  final Widget child;

  /// 外框高度（[heightIsMinimum] 为 true 时是**最小高度**）
  final double? height;

  /// 把 [height] 当作最小高度：内容（校验文案 / maxLength 计数器 / 多行文本）
  /// 更高时外框跟着长高，而不是把内容裁掉或让它画到框外。
  ///
  /// 文本 / 下拉这类用 `InputDecoration` 渲染内联错误的字段必须为 true；
  /// 其余字段（日期 / 复选 / 单选 / 多选 / 按钮）高度由内容决定，固定高度即可。
  final bool heightIsMinimum;

  /// 外框宽度
  final double? width;

  /// 外框装饰
  final Decoration? decoration;

  /// 外框外边距
  final EdgeInsetsGeometry? margin;

  /// 外框内边距
  final EdgeInsetsGeometry? padding;

  /// 内容 Y 轴偏移（非 null 时通过 transform 实现）
  final double? yOffset;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        leading ?? const SizedBox.shrink(),
        Expanded(
          child: Container(
            transform: yOffset != null ? Matrix4.translationValues(0, yOffset!, 0) : null,
            child: child,
          ),
        ),
        ...?actions,
      ],
    );
    final minHeight = heightIsMinimum ? height : null;
    return Container(
      height: heightIsMinimum ? null : height,
      constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      width: width,
      // 有 minHeight 时不能用 Container(alignment:)：它内部的 Align 在
      // 有界父级里会撑满 max 高度。改为按内容收缩后再由 minHeight 抬起。
      alignment: minHeight == null ? Alignment.center : null,
      decoration: decoration,
      margin: margin,
      padding: padding,
      child: minHeight == null
          ? content
          : Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: content,
            ),
    );
  }

  /// 用 [WFormFieldShell] 包装字段（bordered 构建路径）
  ///
  /// 空 name 校验集中在这里，替代此前 7 处重复的 `ArgumentError` 抛出。
  static Widget border({
    required String name,
    required Widget child,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool enableFocusBorder = true,
    bool rendersInlineError = true,
    bool readOnly = false,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }
    return WFormFieldShell(
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      rendersInlineError: rendersInlineError,
      child: child,
    );
  }
}
