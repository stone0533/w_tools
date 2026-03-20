import 'package:flutter/material.dart';

/// 增强版容器组件
class WContainer extends StatelessWidget {
  /// 容器配置
  final WContainerConfig config;

  /// 子组件
  final Widget? child;

  /// 创建容器
  const WContainer({super.key, required this.config, this.child});

  /// 创建带有指定内边距的容器
  ///
  /// @param padding 内边距
  /// @param child 子组件
  /// @param key 组件键
  factory WContainer.padding({
    required EdgeInsetsGeometry padding,
    Widget? child,
    Key? key,
  }) {
    final config = WContainerConfig()
      ..padding = padding;
    return WContainer(
      key: key,
      config: config,
      child: child,
    );
  }

  /// 创建带有指定外边距的容器
  ///
  /// @param margin 外边距
  /// @param child 子组件
  /// @param key 组件键
  factory WContainer.margin({
    required EdgeInsetsGeometry margin,
    Widget? child,
    Key? key,
  }) {
    final config = WContainerConfig()
      ..margin = margin;
    return WContainer(
      key: key,
      config: config,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: config._border,
        borderRadius: config._borderRadius,
        color: config._color,
        boxShadow: config._boxShadow,
        shape: config._shape,
        gradient: config._gradient,
      ),
      width: config._width,
      height: config._height,
      alignment: config._alignment,
      margin: config._margin,
      padding: config._padding,
      clipBehavior: config._clipBehavior,
      transform: config._transform,
      constraints: config._constraints,
      child: child,
    );
  }
}

/// 容器配置类
class WContainerConfig {
  /// 构建容器组件
  ///
  /// @param child 子组件
  /// @param key 组件键
  /// @return WContainer 实例
  WContainer build({Widget? child, Key? key}) {
    return WContainer(
      key: key,
      config: this,
      child: child,
    );
  }
  double? _width;
  double? _height;
  BoxBorder? _border;
  BorderRadiusGeometry? _borderRadius;
  Color? _color;
  AlignmentGeometry? _alignment;
  EdgeInsetsGeometry? _margin;
  EdgeInsetsGeometry? _padding;
  List<BoxShadow>? _boxShadow;
  Clip _clipBehavior = Clip.none;
  BoxShape _shape = BoxShape.rectangle;
  Gradient? _gradient;
  Matrix4? _transform;
  BoxConstraints? _constraints;

  /// 设置宽度
  set width(double? value) {
    _width = value;
  }

  /// 设置高度
  set height(double? value) {
    _height = value;
  }

  /// 设置边框
  set border(BoxBorder? value) {
    _border = value;
  }

  /// 设置边框半径
  set borderRadius(BorderRadiusGeometry? value) {
    _borderRadius = value;
  }

  /// 设置颜色
  set color(Color? value) {
    _color = value;
  }

  /// 设置对齐方式
  set alignment(AlignmentGeometry? value) {
    _alignment = value;
  }

  /// 设置外边距
  set margin(EdgeInsetsGeometry? value) {
    _margin = value;
  }

  /// 设置内边距
  set padding(EdgeInsetsGeometry? value) {
    _padding = value;
  }

  /// 设置阴影
  set boxShadow(List<BoxShadow>? value) {
    _boxShadow = value;
  }

  /// 设置裁剪行为
  set clipBehavior(Clip value) {
    _clipBehavior = value;
  }

  /// 设置形状
  set shape(BoxShape value) {
    _shape = value;
  }

  /// 设置渐变
  set gradient(Gradient? value) {
    _gradient = value;
  }

  /// 设置变换矩阵
  set transform(Matrix4? value) {
    _transform = value;
  }

  /// 设置约束
  set constraints(BoxConstraints? value) {
    _constraints = value;
  }

  /// 设置宽高相同
  WContainerConfig size(double? size) {
    _height = size;
    _width = size;
    return this;
  }

  /// 设置四周边框
  WContainerConfig borderAll(double width, Color color) {
    _border = Border.all(width: width, color: color);
    return this;
  }

  /// 设置底部边框
  WContainerConfig borderBottom(double width, Color color) {
    _border = Border(
      bottom: BorderSide(width: width, color: color),
    );
    return this;
  }

  /// 设置四角边框半径
  WContainerConfig borderRadiusAll(double radius) {
    _borderRadius = BorderRadius.all(Radius.circular(radius));
    return this;
  }

  /// 设置顶部边框半径
  WContainerConfig borderRadiusTop(double radius) {
    _borderRadius = BorderRadius.vertical(top: Radius.circular(radius));
    return this;
  }

  /// 设置居中对齐
  WContainerConfig center() {
    _alignment = Alignment.center;
    return this;
  }

  /// 设置左对齐
  WContainerConfig centerLeft() {
    _alignment = Alignment.centerLeft;
    return this;
  }

  /// 设置右对齐
  WContainerConfig centerRight() {
    _alignment = Alignment.centerRight;
    return this;
  }

  /// 设置对称外边距
  WContainerConfig marginSymmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) {
    _margin = EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
    return this;
  }

  /// 设置所有内边距
  WContainerConfig paddingAll(double value) {
    _padding = EdgeInsets.all(value);
    return this;
  }

  /// 设置对称内边距
  WContainerConfig paddingSymmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) {
    _padding = EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
    return this;
  }

  /// 设置抗锯齿裁剪
  WContainerConfig clipBehaviorAntiAlias() {
    _clipBehavior = Clip.antiAlias;
    return this;
  }

  /// 设置圆形形状
  WContainerConfig shapeCircle() {
    _shape = BoxShape.circle;
    return this;
  }

  /// 设置从上到下的线性渐变
  WContainerConfig gradientLinearTopToBottom(List<Color> colors) {
    _gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    return this;
  }

  /// 设置 Y 轴变换
  WContainerConfig transformY(double y) {
    _transform = Matrix4.translationValues(0, y, 0);
    return this;
  }

  /// 设置最小高度约束
  WContainerConfig constraintsMinHeight(double minHeight) {
    _constraints = BoxConstraints(minHeight: minHeight);
    return this;
  }

  /// 创建一个新的配置实例，可选择性地覆盖属性
  WContainerConfig copyWith({
    double? width,
    double? height,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    Color? color,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? boxShadow,
    Clip? clipBehavior,
    BoxShape? shape,
    Gradient? gradient,
    Matrix4? transform,
    BoxConstraints? constraints,
  }) {
    final config = WContainerConfig();
    config._width = width ?? _width;
    config._height = height ?? _height;
    config._border = border ?? _border;
    config._borderRadius = borderRadius ?? _borderRadius;
    config._color = color ?? _color;
    config._alignment = alignment ?? _alignment;
    config._margin = margin ?? _margin;
    config._padding = padding ?? _padding;
    config._boxShadow = boxShadow ?? _boxShadow;
    config._clipBehavior = clipBehavior ?? _clipBehavior;
    config._shape = shape ?? _shape;
    config._gradient = gradient ?? _gradient;
    config._transform = transform ?? _transform;
    config._constraints = constraints ?? _constraints;
    return config;
  }

  /// 创建当前配置的副本
  WContainerConfig copy() {
    return copyWith();
  }
}
