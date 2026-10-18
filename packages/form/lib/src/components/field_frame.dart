import 'package:flutter/material.dart';

import 'border/border_with_data.dart';

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
/// 空 name 校验 + `WFormBorderWithData` 包装（内层装饰由调用方清空）。
///
/// 字段之间的语义差异（text 的 `readOnly`、其他字段的 `enabled`）仍由各字段
/// 自行计算后传入，不进入本类的接口。
class WFormFieldFrame extends StatelessWidget {
  /// 创建字段外框
  const WFormFieldFrame({
    super.key,
    required this.child,
    this.height,
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

  /// 外框高度
  final double? height;

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
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: decoration,
      margin: margin,
      padding: padding,
      child: Row(
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
      ),
    );
  }

  /// 用 [WFormBorderWithData] 包装字段（bordered 构建路径）
  ///
  /// 空 name 校验集中在这里，替代此前 7 处重复的 `ArgumentError` 抛出。
  static Widget border({
    required String name,
    required Widget child,
    Key? borderKey,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    bool enableFocusBorder = true,
    bool readOnly = false,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }
    return WFormBorderWithData(
      key: borderKey,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly,
      enableFocusBorder: enableFocusBorder,
      child: child,
    );
  }
}
