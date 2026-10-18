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

/// 边框与消息的布局策略
///
/// 内置 [column]（边框在上、消息在下）；需要其他排布时：
/// - 用 [builder] 传入函数式实现，无需建类；
/// - 或继承本类并覆写 [build]。
abstract class WFormBorderLayout {
  const WFormBorderLayout();

  /// 默认布局：边框在上、消息在下
  static const WFormBorderLayout column = WFormBorderColumnLayout();

  /// 函数式布局（无需建类）
  static WFormBorderLayout builder(WFormBorderLayoutBuilder builder) =>
      WFormBorderBuilderLayout(builder);

  /// 组装边框与消息
  Widget build(BuildContext context, WFormBorderLayoutData data);
}

/// 布局构建函数
typedef WFormBorderLayoutBuilder =
    Widget Function(
      BuildContext context,
      WFormBorderLayoutData data,
    );

/// 默认布局实现：边框在上、消息在下
class WFormBorderColumnLayout extends WFormBorderLayout {
  /// 消息与边框的间距
  final double spacing;

  /// 消息的对齐方式
  final CrossAxisAlignment alignment;

  const WFormBorderColumnLayout({
    this.spacing = 4,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context, WFormBorderLayoutData data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        data.child,
        if (data.hasMessage) ...[
          SizedBox(height: spacing),
          data.message,
        ],
      ],
    );
  }
}

/// 函数式布局实现
class WFormBorderBuilderLayout extends WFormBorderLayout {
  /// 布局构建函数
  final WFormBorderLayoutBuilder builder;

  const WFormBorderBuilderLayout(this.builder);

  @override
  Widget build(BuildContext context, WFormBorderLayoutData data) => builder(context, data);
}
