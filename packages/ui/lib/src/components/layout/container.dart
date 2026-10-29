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
  /// - [padding]：内边距
  /// - [child]：子组件
  /// - [key]：组件键
  factory WContainer.padding({
    required EdgeInsetsGeometry padding,
    Widget? child,
    Key? key,
  }) {
    final config = WContainerConfig()..padding = padding;
    return WContainer(
      key: key,
      config: config,
      child: child,
    );
  }

  /// 创建带有指定外边距的容器
  ///
  /// - [margin]：外边距
  /// - [child]：子组件
  /// - [key]：组件键
  factory WContainer.margin({
    required EdgeInsetsGeometry margin,
    Widget? child,
    Key? key,
  }) {
    final config = WContainerConfig()..margin = margin;
    return WContainer(
      key: key,
      config: config,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    config.validate();
    return Container(
      decoration: BoxDecoration(
        border: config._border,
        borderRadius: config._borderRadius,
        color: config._color,
        boxShadow: config._boxShadow,
        shape: config._shape,
        gradient: config._gradient,
      ),
      foregroundDecoration: config._foregroundDecoration,
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
  static const Object _unset = Object();

  // 私有属性
  double? _width;
  double? _height;
  BoxBorder? _border;
  BorderRadiusGeometry? _borderRadius;
  Color? _color;
  AlignmentGeometry? _alignment;
  EdgeInsetsGeometry? _margin;
  EdgeInsetsGeometry? _padding;
  List<BoxShadow>? _boxShadow;
  Decoration? _foregroundDecoration;
  Clip _clipBehavior = Clip.none;
  BoxShape _shape = BoxShape.rectangle;
  Gradient? _gradient;
  Matrix4? _transform;
  BoxConstraints? _constraints;

  /// 构建容器组件
  ///
  /// - [child]：子组件
  /// - [key]：组件键
  /// 返回：WContainer 实例
  WContainer build({Widget? child, Key? key}) {
    return WContainer(
      key: key,
      config: this,
      child: child,
    );
  }

  // 属性 Setter
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

  /// 设置前景装饰（例如不占宽度的描边）
  set foregroundDecoration(Decoration? value) {
    _foregroundDecoration = value;
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

  // 链式调用方法
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
    assert(minHeight >= 0 && minHeight.isFinite, 'minHeight 必须非负');
    _constraints = (_constraints ?? const BoxConstraints()).copyWith(
      minHeight: minHeight,
    );
    return this;
  }

  // 复制方法
  /// 创建一个新的配置实例，可选择性地覆盖属性
  WContainerConfig copyWith({
    Object? width = _unset,
    Object? height = _unset,
    Object? border = _unset,
    Object? borderRadius = _unset,
    Object? color = _unset,
    Object? alignment = _unset,
    Object? margin = _unset,
    Object? padding = _unset,
    Object? boxShadow = _unset,
    Object? foregroundDecoration = _unset,
    Clip? clipBehavior,
    BoxShape? shape,
    Object? gradient = _unset,
    Object? transform = _unset,
    Object? constraints = _unset,
  }) {
    final config = WContainerConfig();
    config._width = identical(width, _unset) ? _width : width as double?;
    config._height = identical(height, _unset) ? _height : height as double?;
    config._border = identical(border, _unset) ? _border : border as BoxBorder?;
    config._borderRadius =
        identical(borderRadius, _unset) ? _borderRadius : borderRadius as BorderRadiusGeometry?;
    config._color = identical(color, _unset) ? _color : color as Color?;
    config._alignment = identical(alignment, _unset) ? _alignment : alignment as AlignmentGeometry?;
    config._margin = identical(margin, _unset) ? _margin : margin as EdgeInsetsGeometry?;
    config._padding = identical(padding, _unset) ? _padding : padding as EdgeInsetsGeometry?;
    config._boxShadow = identical(boxShadow, _unset) ? _boxShadow : boxShadow as List<BoxShadow>?;
    config._foregroundDecoration = identical(foregroundDecoration, _unset)
        ? _foregroundDecoration
        : foregroundDecoration as Decoration?;
    config._clipBehavior = clipBehavior ?? _clipBehavior;
    config._shape = shape ?? _shape;
    config._gradient = identical(gradient, _unset) ? _gradient : gradient as Gradient?;
    config._transform = identical(transform, _unset) ? _transform : transform as Matrix4?;
    config._constraints =
        identical(constraints, _unset) ? _constraints : constraints as BoxConstraints?;
    return config;
  }

  /// 校验配置，尽量在构建前暴露非法组合。
  void validate() {
    assert(
      _shape != BoxShape.circle || _borderRadius == null,
      'WContainerConfig: shapeCircle 与 borderRadius 不能同时设置',
    );
    assert(
      _width == null || (_width!.isFinite && _width! >= 0),
      'WContainerConfig.width 必须是非负有限值',
    );
    assert(
      _height == null || (_height!.isFinite && _height! >= 0),
      'WContainerConfig.height 必须是非负有限值',
    );
  }

  /// 创建当前配置的副本
  WContainerConfig copy() {
    return copyWith();
  }
}
