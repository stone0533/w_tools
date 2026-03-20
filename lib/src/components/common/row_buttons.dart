import 'package:flutter/material.dart';



/// 横向滚动按钮组件，用于创建可横向滚动的按钮列表
///
/// 该组件支持以下功能：
/// - 横向滚动的按钮列表布局
/// - 点击按钮时滚动到中央位置
/// - 自定义按钮样式和点击回调
/// - 支持滚动回调和自定义滚动物理特性
/// - 支持自定义滚动曲线和动画持续时间
/// - 支持按钮选择状态管理
class WRowButtons extends StatefulWidget {
  /// 构造函数
  ///
  /// [key] 组件键
  /// [controller] 控制器，用于管理按钮的选中状态和滚动
  /// [builder] 按钮构建器，用于自定义按钮样式
  /// [padding] 内边距，默认 null
  /// [onTap] 点击回调，当按钮被点击时触发
  /// [onCanTap] 是否可以点击回调，返回 false 时按钮不可点击
  /// [spacing] 按钮间距，默认 0.0
  /// [physics] 滚动物理特性，默认 null
  /// [onScroll] 滚动回调，当滚动位置变化时触发
  const WRowButtons({
    super.key,
    required this.controller,
    required this.builder,
    this.padding,
    this.onTap,
    this.onCanTap,
    this.spacing = 0.0,
    this.physics,
    this.onScroll,
  });

  /// 按钮构建器
  ///
  /// [context] 构建上下文
  /// [index] 按钮索引
  /// [isSelected] 是否选中
  final Widget Function(BuildContext context, int index, bool isSelected) builder;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 点击回调
  ///
  /// [index] 被点击的按钮索引
  final ValueChanged<int>? onTap;

  /// 控制器
  final WRowButtonsController controller;

  /// 是否可以点击回调
  ///
  /// [index] 按钮索引
  final bool Function(int index)? onCanTap;

  /// 按钮间距
  final double spacing;

  /// 滚动物理特性
  final ScrollPhysics? physics;

  /// 滚动回调
  ///
  /// [offset] 滚动偏移量
  final ValueChanged<double>? onScroll;

  @override
  State<WRowButtons> createState() => _WRowButtonsState();
}

/// WRowButtons 的状态类
class _WRowButtonsState extends State<WRowButtons> {
  /// 滚动控制器
  late ScrollController scrollController;

  /// 当前选中的索引
  late int currentIndex;

  @override
  void initState() {
    scrollController = widget.controller.scrollController;
    currentIndex = widget.controller.index;
    super.initState();

    // 添加索引变化监听器
    widget.controller.addListener(() {
      setState(() {
        currentIndex = widget.controller.index;
      });
    });

    // 添加滚动监听器
    if (widget.onScroll != null) {
      scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    // 移除滚动监听器
    if (widget.onScroll != null) {
      scrollController.removeListener(_onScroll);
    }
    // 调用控制器的 dispose 方法释放资源
    widget.controller.dispose();
    super.dispose();
  }

  /// 滚动监听器回调
  void _onScroll() {
    if (widget.onScroll != null) {
      widget.onScroll!(scrollController.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints boxConstraints) {
        widget.controller.updateBoxConstraints(boxConstraints);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          physics: widget.physics,
          child: Container(
            padding: widget.padding,
            child: Wrap(
              spacing: widget.spacing,
              children: List.generate(
                widget.controller.length,
                (index) => _ButtonItem(
                  key: widget.controller._keys[index],
                  index: index,
                  isSelected: currentIndex == index,
                  builder: widget.builder,
                  onTap: widget.onTap,
                  onCanTap: widget.onCanTap,
                  controller: widget.controller,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 按钮项组件，用于减少不必要的重建
class _ButtonItem extends StatelessWidget {
  /// 构造函数
  const _ButtonItem({
    super.key,
    required this.index,
    required this.isSelected,
    required this.builder,
    required this.onTap,
    required this.onCanTap,
    required this.controller,
  });

  /// 按钮索引
  final int index;

  /// 是否选中
  final bool isSelected;

  /// 按钮构建器
  final Widget Function(BuildContext context, int index, bool isSelected) builder;

  /// 点击回调
  final ValueChanged<int>? onTap;

  /// 是否可以点击回调
  final bool Function(int index)? onCanTap;

  /// 控制器
  final WRowButtonsController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onCanTap?.call(index) == false) {
            return;
          }
          onTap?.call(index);
          controller.animateTo(index);
        },
        child: builder(context, index, isSelected),
      ),
    );
  }

}

/// 横向滚动按钮控制器，用于管理按钮的选中状态和滚动
///
/// 该控制器提供以下功能：
/// - 管理按钮数量和当前选中索引
/// - 处理滚动动画逻辑
/// - 提供索引变化通知机制
/// - 支持自定义滚动曲线和对齐方式
class WRowButtonsController {
  /// 默认动画持续时间
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 600);

  /// 按钮数量
  final int length;

  /// 当前选中的索引
  int _index;

  /// 按钮的全局键，用于获取按钮的位置信息
  late List<GlobalKey> _keys;

  /// 布局约束，用于计算滚动位置
  BoxConstraints? _boxConstraints;

  /// 更新布局约束
  ///
  /// [constraints] 新的布局约束
  void updateBoxConstraints(BoxConstraints constraints) {
    _boxConstraints = constraints;
  }

  /// 滚动控制器，用于控制横向滚动
  late ScrollController scrollController;

  /// 动画持续时间，默认 600 毫秒
  Duration? animationDuration;

  /// 是否滚动到中心，默认 true
  bool scrollToCenter;

  /// 滚动曲线，默认 Curves.ease
  final Curve scrollCurve;

  /// 是否启用滚动动画，默认 true
  final bool animateScroll;

  /// 过度滚动量，默认 0.0
  final double overScroll;

  /// 滚动阈值，默认 0.5
  final double scrollThreshold;

  /// 索引变化通知器，用于通知索引变化
  final ValueNotifier<int> _indexNotifier;

  /// 获取当前选中的索引
  int get index => _index;

  /// 获取选中状态通知器
  ///
  /// 可以通过监听此通知器来获取选中状态的变化
  ValueNotifier<int> get selectedIndexNotifier => _indexNotifier;

  /// 构造函数
  ///
  /// [length] 按钮数量
  /// [initialIndex] 初始选中的索引，默认 0
  /// [animationDuration] 动画持续时间
  /// [scrollToCenter] 是否滚动到中心，默认 true
  /// [scrollCurve] 滚动曲线，默认 Curves.ease
  /// [animateScroll] 是否启用滚动动画，默认 true
  /// [overScroll] 过度滚动量，默认 0.0
  /// [scrollThreshold] 滚动阈值，默认 0.5
  WRowButtonsController({
    required this.length,
    int initialIndex = 0,
    this.animationDuration,
    this.scrollToCenter = true,
    this.scrollCurve = Curves.ease,
    this.animateScroll = true,
    this.overScroll = 0.0,
    this.scrollThreshold = 0.5,
  }) : _index = initialIndex,
       _indexNotifier = ValueNotifier(initialIndex) {
    // 检查按钮数量是否为正数
    if (length <= 0) {
      throw ArgumentError('按钮数量必须为正数');
    }

    // 检查初始索引是否在有效范围内
    if (initialIndex < 0 || initialIndex >= length) {
      throw ArgumentError('初始索引必须在有效范围内');
    }

    _keys = List.generate(length, (_) => GlobalKey());
    scrollController = ScrollController();
    animationDuration = _defaultAnimationDuration;
  }

  /// 添加监听器
  ///
  /// [listener] 监听器
  void addListener(VoidCallback listener) {
    _indexNotifier.addListener(listener);
  }

  /// 移除监听器
  ///
  /// [listener] 监听器
  void removeListener(VoidCallback listener) {
    _indexNotifier.removeListener(listener);
  }

  /// 更改索引
  ///
  /// [value] 新的索引
  /// [duration] 动画持续时间
  /// [curve] 动画曲线
  void _changeIndex(
    int value, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) {
    // 确保索引在有效范围内
    if (value < 0 || value >= length) {
      return;
    }

    _index = value;
    _indexNotifier.value = _index;

    if (scrollToCenter == false || _boxConstraints == null) {
      return;
    }

    // 滚动到选中的按钮
    _scrollToButton(value, duration: duration, curve: curve);
  }

  /// 处理边界情况
  ///
  /// [targetScrollOffset] 目标滚动偏移量
  /// [translation] 按钮的全局位置
  /// [size] 按钮的大小
  /// 返回处理后的目标滚动偏移量
  double _handleBoundaryConditions(double targetScrollOffset, Offset translation, Size size) {
    // 边界情况处理
    if ((translation.dx + scrollController.offset + (size.width / 2)) < _boxConstraints!.maxWidth / 2) {
      return scrollController.position.minScrollExtent;
    } else if (translation.dx + scrollController.offset + (size.width / 2) - scrollController.position.maxScrollExtent > _boxConstraints!.maxWidth / 2) {
      return scrollController.position.maxScrollExtent;
    }
    return targetScrollOffset;
  }

  /// 计算目标滚动偏移量
  ///
  /// [translation] 按钮的全局位置
  /// [size] 按钮的大小
  /// 返回计算后的目标滚动偏移量
  double _calculateTargetOffset(Offset translation, Size size) {
    // 按钮左侧到容器中心的偏移量
    double buttonLeftToCenterOffset = translation.dx - (_boxConstraints!.maxWidth - size.width) / 2;
    // 目标滚动偏移量
    double targetScrollOffset = buttonLeftToCenterOffset + scrollController.offset;
    
    // 处理边界情况
    targetScrollOffset = _handleBoundaryConditions(targetScrollOffset, translation, size);
    
    // 应用过度滚动量
    targetScrollOffset = targetScrollOffset.clamp(
      scrollController.position.minScrollExtent - overScroll,
      scrollController.position.maxScrollExtent + overScroll
    );
    
    // 确保滚动位置在有效范围内
    return targetScrollOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent
    );
  }

  /// 滚动到指定按钮
  ///
  /// [index] 按钮索引
  /// [duration] 动画持续时间
  /// [curve] 动画曲线
  void _scrollToButton(
    int index, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) {
    try {
      // 检查索引是否在有效范围内
      if (index < 0 || index >= length) {
        return;
      }

      // 检查滚动控制器是否有效
      if (!scrollController.hasClients) {
        return;
      }

      RenderObject? evaluationRenderObject = _keys[index].currentContext?.findRenderObject();
      final translation = evaluationRenderObject?.getTransformTo(null).getTranslation();
      final Size? size = evaluationRenderObject?.semanticBounds.size;

      if (translation == null || size == null) {
        // 渲染对象还未准备好，延迟执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToButton(index, duration: duration, curve: curve);
        });
        return;
      }

      // 计算目标滚动位置
      double targetOffset = _calculateTargetOffset(Offset(translation.x, translation.y), size);

      // 执行滚动
      if (!animateScroll || duration == null || duration <= Duration.zero) {
        scrollController.jumpTo(targetOffset);
      } else {
        scrollController.animateTo(targetOffset, duration: duration, curve: curve);
      }
    } catch (e) {
      // 捕获异常，避免应用崩溃
      // 生产环境中可以使用日志框架记录错误
      // 调试时可以取消注释下面的代码
      // debugPrint('滚动到按钮时发生错误: $e');
    }
  }

  /// 动画滚动到指定索引
  ///
  /// [value] 目标索引
  /// [curve] 动画曲线，默认使用控制器的 scrollCurve
  void animateTo(int value, {Curve? curve}) {
    _changeIndex(value, duration: animationDuration, curve: curve ?? scrollCurve);
  }

  /// 直接跳转到指定索引
  ///
  /// [value] 目标索引
  void jumpTo(int value) {
    _changeIndex(value);
  }

  /// 释放资源
  ///
  /// 调用此方法以释放控制器使用的资源，避免内存泄漏
  void dispose() {
    scrollController.dispose();
    _indexNotifier.dispose();
  }
}
