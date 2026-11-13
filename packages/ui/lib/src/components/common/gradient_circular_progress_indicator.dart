import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 带渐变效果的圆形进度指示器
class WGradientCircularProgressIndicator extends StatefulWidget {
  /// 构造函数
  ///
  /// - [key]：组件键
  /// - [strokeWidth]：进度条宽度
  /// - [radius]：圆的半径
  /// - [colors]：渐变色数组
  /// - [stops]：渐变色的终止点，对应colors属性
  /// - [strokeCapRound]：两端是否为圆角
  /// - [backgroundColor]：进度条背景色
  /// - [totalAngle]：进度条的总弧度，2*PI为整圆，小于2*PI则不是整圆
  /// - [value]：当前进度，取值范围 [0.0-1.0]；[indeterminate] 为 true 时忽略
  /// - [indeterminate]：不确定进度（旋转的弧段），用于不知道总进度的加载
  const WGradientCircularProgressIndicator({
    super.key,
    this.strokeWidth = 2.0,
    required this.radius,
    required this.colors,
    this.stops,
    this.strokeCapRound = false,
    this.backgroundColor,
    this.totalAngle = 2 * pi,
    this.value = 0,
    this.indeterminate = false,
    this.semanticsLabel,
  }) : assert(radius > 0, 'radius 必须大于 0'),
       assert(strokeWidth > 0, 'strokeWidth 必须大于 0'),
       assert(strokeWidth < radius * 2, 'strokeWidth 必须小于直径');

  /// 进度条宽度
  final double strokeWidth;

  /// 圆的半径
  final double radius;

  /// 两端是否为圆角
  final bool strokeCapRound;

  /// 当前进度，取值范围 [0.0-1.0]；[indeterminate] 为 true 时忽略
  final double value;

  /// 是否显示不确定进度；true 时旋转一段固定弧长，语义 value 为 null
  final bool indeterminate;

  /// 进度条背景色；为 null 时取 `ColorScheme.surfaceContainerHighest`。
  final Color? backgroundColor;

  /// 进度条的总弧度，2*PI为整圆，小于2*PI则不是整圆
  final double totalAngle;

  /// 渐变色数组
  final List<Color> colors;

  /// 无障碍标签；为 null 时只暴露进度 value
  final String? semanticsLabel;

  /// 渐变色的终止点，对应colors属性
  final List<double>? stops;

  @override
  State<WGradientCircularProgressIndicator> createState() =>
      _WGradientCircularProgressIndicatorState();
}

class _WGradientCircularProgressIndicatorState extends State<WGradientCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.indeterminate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WGradientCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.indeterminate != oldWidget.indeterminate) {
      if (widget.indeterminate) {
        _controller.repeat();
      } else {
        _controller
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.colors.isNotEmpty, 'colors 不能为空');
    assert(
      widget.stops == null || widget.stops!.length == widget.colors.length,
      'stops 长度必须与 colors 一致',
    );
    assert(widget.value.isFinite, 'value 必须是有限数');

    double offset = .0;
    // 如果两端为圆角，则需要对起始位置进行调整，否则圆角部分会偏离起始位置
    if (widget.strokeCapRound) {
      offset = asin(
        (widget.strokeWidth / (widget.radius * 2 - widget.strokeWidth)).clamp(-1.0, 1.0),
      );
    }
    final progress = widget.value.isFinite ? widget.value.clamp(0.0, 1.0) : 0.0;
    final background =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: widget.semanticsLabel,
      value: widget.indeterminate ? null : '${(progress * 100).round()}%',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rotation =
              -pi / 2.0 - offset + (widget.indeterminate ? _controller.value * 2 * pi : 0.0);
          return Transform.rotate(angle: rotation, child: child);
        },
        child: CustomPaint(
          size: Size.fromRadius(widget.radius),
          painter: _WGradientCircularProgressPainter(
            strokeWidth: widget.strokeWidth,
            strokeCapRound: widget.strokeCapRound,
            backgroundColor: background,
            value: widget.indeterminate ? 0.25 : progress,
            total: widget.totalAngle,
            radius: widget.radius,
            colors: widget.colors,
            stops: widget.stops,
          ),
        ),
      ),
    );
  }
}

// 实现画笔
class _WGradientCircularProgressPainter extends CustomPainter {
  /// 构造函数
  ///
  /// - [strokeWidth]：进度条宽度
  /// - [strokeCapRound]：两端是否为圆角
  /// - [backgroundColor]：进度条背景色
  /// - [radius]：圆的半径
  /// - [total]：进度条的总弧度
  /// - [colors]：渐变色数组
  /// - [stops]：渐变色的终止点
  /// - [value]：当前进度
  _WGradientCircularProgressPainter({
    required this.strokeWidth,
    this.strokeCapRound = false,
    required this.backgroundColor,
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
      startAngle = asin((strokeWidth / (size.width - strokeWidth)).clamp(-1.0, 1.0));
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
        !listEquals(oldDelegate.colors, colors) ||
        oldDelegate.total != total ||
        oldDelegate.radius != radius ||
        !listEquals(oldDelegate.stops, stops);
  }
}
