/// 纯 Dart 的几何类型（CLI 包不依赖 `dart:ui`，才能在 `dart test` 里跑）。
class DPoint {
  const DPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

class DRect {
  const DRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  /// 四边内缩 [v]。
  DRect deflate(double v) => DRect(left + v, top + v, width - 2 * v, height - 2 * v);

  /// 以中心为准，换成给定宽高。
  DRect withSize(double w, double h) => DRect(centerX - w / 2, centerY - h / 2, w, h);

  @override
  String toString() => 'DRect($left, $top, $width × $height)';
}
