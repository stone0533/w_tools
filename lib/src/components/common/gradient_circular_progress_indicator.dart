import 'dart:math';

import 'package:flutter/material.dart';

/// 带渐变效果的圆形进度指示器
class WGradientCircularProgressIndicator extends StatelessWidget {
  /// 构造函数
  ///
  /// @param key 组件键
  /// @param strokeWidth 进度条宽度
  /// @param radius 圆的半径
  /// @param colors 渐变色数组
  /// @param stops 渐变色的终止点，对应colors属性
  /// @param strokeCapRound 两端是否为圆角
  /// @param backgroundColor 进度条背景色
  /// @param totalAngle 进度条的总弧度，2*PI为整圆，小于2*PI则不是整圆
  /// @param value 当前进度，取值范围 [0.0-1.0]
  const WGradientCircularProgressIndicator({
    super.key,
    this.strokeWidth = 2.0,
    required this.radius,
    required this.colors,
    this.stops,
    this.strokeCapRound = false,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.totalAngle = 2 * pi,
    this.value = 0,
  });

  /// 进度条宽度
  final double strokeWidth;

  /// 圆的半径
  final double radius;

  /// 两端是否为圆角
  final bool strokeCapRound;

  /// 当前进度，取值范围 [0.0-1.0]
  final double value;

  /// 进度条背景色
  final Color backgroundColor;

  /// 进度条的总弧度，2*PI为整圆，小于2*PI则不是整圆
  final double totalAngle;

  /// 渐变色数组
  final List<Color> colors;

  /// 渐变色的终止点，对应colors属性
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    double offset = .0;
    // 如果两端为圆角，则需要对起始位置进行调整，否则圆角部分会偏离起始位置
    if (strokeCapRound) {
      offset = asin(strokeWidth / (radius * 2 - strokeWidth));
    }
    return Transform.rotate(
      angle: -pi / 2.0 - offset,
      child: CustomPaint(
        size: Size.fromRadius(radius),
        painter: _WGradientCircularProgressPainter(
          strokeWidth: strokeWidth,
          strokeCapRound: strokeCapRound,
          backgroundColor: backgroundColor,
          value: value,
          total: totalAngle,
          radius: radius,
          colors: colors,
          stops: stops,
        ),
      ),
    );
  }
}

// 实现画笔
class _WGradientCircularProgressPainter extends CustomPainter {
  /// 构造函数
  ///
  /// @param strokeWidth 进度条宽度
  /// @param strokeCapRound 两端是否为圆角
  /// @param backgroundColor 进度条背景色
  /// @param radius 圆的半径
  /// @param total 进度条的总弧度
  /// @param colors 渐变色数组
  /// @param stops 渐变色的终止点
  /// @param value 当前进度
  _WGradientCircularProgressPainter({
    required this.strokeWidth,
    this.strokeCapRound = false,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.radius,
    this.total = 2 * pi,
    required this.colors,
    this.stops,
    this.value,
  });

  final double strokeWidth;
  final bool strokeCapRound;
  final double? value;
  final Color backgroundColor;
  final List<Color> colors;
  final double total;
  final double? radius;
  final List<double>? stops;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius != null) {
      size = Size.fromRadius(radius!);
    }
    double offset = strokeWidth / 2.0;
    double progressValue = (value ?? .0).clamp(0.0, 1.0) * total;
    double startAngle = .0;

    if (strokeCapRound) {
      startAngle = asin(strokeWidth / (size.width - strokeWidth));
    }

    Rect rect = Offset(offset, offset) & Size(size.width - strokeWidth, size.height - strokeWidth);

    var paint = Paint()
      ..strokeCap = strokeCapRound ? StrokeCap.round : StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = strokeWidth;

    // 先画背景
    if (backgroundColor != Colors.transparent) {
      paint.color = backgroundColor;
      canvas.drawArc(rect, startAngle, total, false, paint);
    }

    // 再画前景，应用渐变
    if (progressValue > 0) {
      paint.shader = SweepGradient(
        startAngle: 0.0,
        endAngle: progressValue,
        colors: colors,
        stops: stops,
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, progressValue, false, paint);
    }
  }

  @override
  bool shouldRepaint(_WGradientCircularProgressPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.strokeCapRound != strokeCapRound ||
        oldDelegate.value != value ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.colors != colors ||
        oldDelegate.total != total ||
        oldDelegate.radius != radius ||
        oldDelegate.stops != stops;
  }
}

// 示例
// AnimatedBuilder(
//   animation: _controller,
//   builder: (a, b) {
//     return WGradientCircularProgressIndicator(
//       // No gradient
//       colors: [Colors.green, Colors.green],
//       radius: 28,
//       strokeWidth: 4,
//       backgroundColor: Colors.transparent,
//       value: _controller.value,
//     );
//   },
// )
