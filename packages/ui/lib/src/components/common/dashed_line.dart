import 'package:flutter/material.dart';

/// 水平虚线分隔 / 装饰线。
///
/// 设计稿里的虚线通常是容器的 `strokeDashes`（例如 `[2,2]`、1px），
/// 不是独立图形节点；本组件用于卡片行分隔、票据 / 优惠券装饰线等场景。
///
/// 尺寸使用**逻辑像素**，不随设计稿宽度缩放；需要按设计稿缩放时由调用方传入
/// 已缩放的值（例如项目里的 `1.w`，或 `WScreen.of(context).w(1)`）。
///
/// 宽度跟随父级，和 Material `Divider` 一样要求父级宽度有界：
/// 放在 `Column` / `ListView` 里可直接使用；放在 `Row` 里请用 `Expanded` 包裹。
class WDashedLine extends StatelessWidget {
  const WDashedLine({
    super.key,
    this.color,
    this.thickness = 1,
    this.dashWidth = 2,
    this.dashGap = 2,
    this.indent = 0,
    this.endIndent = 0,
  }) : assert(thickness > 0, 'thickness 必须大于 0'),
       assert(dashWidth > 0, 'dashWidth 必须大于 0'),
       assert(dashGap >= 0, 'dashGap 不能为负'),
       assert(indent >= 0, 'indent 不能为负'),
       assert(endIndent >= 0, 'endIndent 不能为负');

  /// 虚线颜色；null 时取 `DividerTheme.color`，再回退 `ColorScheme.outlineVariant`。
  final Color? color;

  /// 线宽（外框高度），默认 1。
  final double thickness;

  /// 单段虚线长度，默认 2。
  final double dashWidth;

  /// 虚线间距，默认 2；传 0 得到实线。
  final double dashGap;

  /// 左侧缩进，默认 0。
  final double indent;

  /// 右侧缩进，默认 0。
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final dividerTheme = DividerTheme.of(context);
    final resolvedColor =
        color ?? dividerTheme.color ?? Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        width: double.infinity,
        height: thickness,
        child: CustomPaint(
          painter: _WDashedLinePainter(
            color: resolvedColor,
            dashWidth: dashWidth,
            dashGap: dashGap,
          ),
        ),
      ),
    );
  }
}

class _WDashedLinePainter extends CustomPainter {
  _WDashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // release 下 assert 被剥离；dashWidth + dashGap <= 0 时直接不画，避免死循环。
    final step = dashWidth + dashGap;
    if (step <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += step) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      if (end > x) {
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WDashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap;
}
