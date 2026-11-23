import 'package:flutter/material.dart';

/// 边框与消息的布局输入
class WFormBorderLayoutData {
  /// 已应用装饰与圆角的子组件
  final Widget child;

  /// 已按状态构建好的消息（无消息时为空 widget）
  final Widget message;

  /// 是否存在消息
  final bool hasMessage;

  /// 是否错误态
  final bool isError;

  /// 是否只读态
  final bool isReadOnly;

  /// 当前生效的圆角（可能为 null）
  final BorderRadius? borderRadius;

  const WFormBorderLayoutData({
    required this.child,
    required this.message,
    required this.hasMessage,
    required this.isError,
    required this.isReadOnly,
    this.borderRadius,
  });
}

/// 边框与消息的布局策略：返回「边框 + 消息」的组装结果。
///
/// 8.0 起布局固定为 [columnBorderLayout]（边框在上、消息在下）：
/// `WFormBorderStyle.layout` 参数与 `WFormBorder` 公开入口已移除，
/// 这里只保留内部组装用的类型与函数。
typedef WFormBorderLayout = Widget Function(BuildContext context, WFormBorderLayoutData data);

/// 默认布局：边框在上、消息在下。
Widget columnBorderLayout(BuildContext context, WFormBorderLayoutData data) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      data.child,
      if (data.hasMessage) ...[const SizedBox(height: 4), data.message],
    ],
  );
}
