import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 增强版列表组件
///
/// 提供丰富的列表功能，支持多种布局模式、子项重叠效果、空列表占位等特性。
///
/// **主要特性:**
/// - 支持普通列表、带分隔线列表、网格布局
/// - 支持头部和尾部组件
/// - 子项重叠效果（卡片堆叠效果）
/// - 空列表占位符
/// - 子项缓存机制
/// - 灵活的样式配置（背景色、圆角、边框）
///
/// **使用示例:**
///
/// ```dart
/// // 1. 创建普通列表
/// WListView(
///   config: WListViewConfig.vertical(),
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   itemCount: 20,
/// )
///
/// // 2. 创建带分隔线的列表
/// WListView.separated(
///   config: WListViewConfig.vertical(),
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   itemCount: 20,
/// )
///
/// // 3. 创建网格布局
/// WListView.grid(
///   config: WListViewConfig.vertical(),
///   itemBuilder: (context, index) => Container(color: Colors.blue),
///   itemCount: 20,
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
/// )
///
/// // 4. 使用配置类构建（推荐）
/// WListViewConfig.card()
///   ..itemExtent = 60
///   ..build(
///     itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///     itemCount: 20,
///     header: Text('Header'),
///     footer: Text('Footer'),
///   )
///
/// // 5. 带重叠效果的列表
/// WListViewConfig.card()
///   ..itemExtent = 100
///   ..useOverlap = true
///   ..overlapOffset = -20
///   ..build(
///     itemBuilder: (context, index) => Card(child: ListTile(title: Text('Card $index'))),
///     itemCount: 10,
///   )
///
/// // 6. 空列表处理
/// WListView(
///   config: WListViewConfig.vertical(),
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   itemCount: 0,
///   emptyWidget: Center(child: Text('暂无数据')),
/// )
/// ```
class WListView extends StatefulWidget {
  /// 列表配置
  final WListViewConfig config;

  /// 子项构建器
  final Widget Function(BuildContext, int) itemBuilder;

  /// 子项数量
  final int itemCount;

  /// 列表控制器
  final ScrollController? controller;

  /// 列表头部
  final Widget? header;

  /// 列表尾部
  final Widget? footer;

  /// 是否启用子项缓存
  final bool cacheItems;

  /// 网格布局代理
  final SliverGridDelegate? gridDelegate;

  /// 空列表占位符组件（优先级高于 config 中的配置）
  final Widget? emptyWidget;

  /// 创建普通列表组件
  ///
  /// - [config]：列表配置对象
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [controller]：滚动控制器
  /// - [header]：头部组件
  /// - [footer]：尾部组件
  /// - [cacheItems]：是否启用缓存
  /// - [gridDelegate]：网格布局代理（可选）
  /// - [emptyWidget]：空列表占位符组件（可选，优先级高于 config）
  const WListView({
    super.key,
    required this.config,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.header,
    this.footer,
    this.cacheItems = false,
    this.gridDelegate,
    this.emptyWidget,
  });

  /// 创建带有分隔线的列表组件
  ///
  /// - [config]：列表配置对象
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [controller]：滚动控制器
  /// - [header]：头部组件
  /// - [footer]：尾部组件
  /// - [cacheItems]：是否启用缓存
  /// - [emptyWidget]：空列表占位符组件（可选，优先级高于 config）
  const WListView.separated({
    super.key,
    required this.config,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.header,
    this.footer,
    this.cacheItems = false,
    this.emptyWidget,
  }) : gridDelegate = null;

  /// 创建网格布局列表组件
  ///
  /// - [config]：列表配置对象
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [gridDelegate]：网格布局代理（必填）
  /// - [controller]：滚动控制器
  /// - [header]：头部组件
  /// - [footer]：尾部组件
  /// - [cacheItems]：是否启用缓存
  /// - [emptyWidget]：空列表占位符组件（可选，优先级高于 config）
  const WListView.grid({
    super.key,
    required this.config,
    required this.itemBuilder,
    required this.itemCount,
    required this.gridDelegate,
    this.controller,
    this.header,
    this.footer,
    this.cacheItems = false,
    this.emptyWidget,
  });

  @override
  State<WListView> createState() => _WListViewState();
}

class _WListViewState extends State<WListView> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void didUpdateWidget(WListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 运行期替换 controller 时同步内部引用；内部创建的 controller 需要释放
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null && _controller != widget.controller) {
        _controller.dispose();
      }
      _controller = widget.controller ?? ScrollController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// 构建列表内容
  Widget _buildListContent() {
    // 处理头部和尾部
    if (widget.header != null || widget.footer != null) {
      return _buildListWithHeaderFooter();
    } else {
      return _buildListWithoutHeaderFooter();
    }
  }

  /// 获取缓存区域大小
  double _getCacheExtent() {
    return widget.config._cacheExtent ??
        (widget.config._scrollDirection == Axis.vertical
            ? WListViewConfig._defaultVerticalCacheExtent
            : WListViewConfig._defaultHorizontalCacheExtent);
  }

  /// 获取有效的子项高度（考虑重叠效果）
  ///
  /// 当启用子项重叠效果时，每个子项的实际布局空间需要调整：
  /// - 子项会向上偏移 `overlapOffset`（负数）
  /// - 因此每个子项实际占用的高度 = itemExtent + overlapOffset
  /// - 结果至少保留 1px，避免非正 itemExtent 触发列表断言
  ///
  /// 返回：考虑重叠效果后的有效子项高度
  double? _getEffectiveItemExtent() {
    if (widget.config._useOverlap && widget.config._overlapOffset != 0.0) {
      final itemExtent = widget.config._itemExtent;
      if (itemExtent != null) {
        // 子项实际占用高度 = 原始高度 + 重叠偏移量（负数）；
        // 至少保留 1px，避免非正 itemExtent 触发列表断言
        return math.max(1.0, itemExtent + widget.config._overlapOffset);
      }
    }
    return widget.config._itemExtent;
  }

  /// 获取有效的内边距（考虑重叠效果）
  ///
  /// 当启用子项重叠效果时，每个子项会向上偏移 `overlapOffset`（负数）。
  /// 由于子项实际占用空间减少（itemExtent + overlapOffset），需要调整底部 padding：
  /// - 底部 padding 增加重叠偏移量的绝对值，确保列表底部有足够空间
  ///
  /// 注意：重叠效果仅支持垂直滚动列表
  ///
  /// 返回：考虑重叠效果后的有效内边距
  EdgeInsetsGeometry? _getEffectivePadding() {
    if (widget.config._useOverlap &&
        widget.config._overlapOffset != 0.0 &&
        widget.config._itemExtent != null &&
        widget.config._scrollDirection == Axis.vertical) {
      final padding = widget.config._padding;
      final overlapCompensation = -widget.config._overlapOffset;

      if (padding is EdgeInsets) {
        return EdgeInsets.only(
          left: padding.left,
          top: padding.top,
          right: padding.right,
          bottom: padding.bottom + overlapCompensation,
        );
      } else if (padding is EdgeInsetsDirectional) {
        return EdgeInsetsDirectional.only(
          start: padding.start,
          top: padding.top,
          end: padding.end,
          bottom: padding.bottom + overlapCompensation,
        );
      }
    }
    return widget.config._padding;
  }

  /// 构建带头部和尾部的列表
  Widget _buildListWithHeaderFooter() {
    final slivers = <Widget>[];

    // 添加头部
    if (widget.header != null) {
      slivers.add(SliverToBoxAdapter(child: widget.header!));
    }

    // 添加列表内容
    slivers.add(_buildListSliver());

    // 添加尾部
    if (widget.footer != null) {
      slivers.add(SliverToBoxAdapter(child: widget.footer!));
    }

    // 使用 CustomScrollView
    // padding 与 header / footer 一起作用于整组 sliver，保持与无 header 分支一致
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: _getEffectivePadding() ?? EdgeInsets.zero,
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
      controller: _controller,
      scrollDirection: widget.config._scrollDirection,
      reverse: widget.config._reverse,
      physics: widget.config._physics,
      // 兼容 Flutter 3.27–3.43：scrollCacheExtent 自 3.41 才提供；
      // 3.44 起 cacheExtent 被标记 deprecated，此处按兼容性保留。
      // ignore: deprecated_member_use
      cacheExtent: _getCacheExtent(),
      shrinkWrap: widget.config._shrinkWrap,
    );
  }

  /// 构建不带头部和尾部的列表
  Widget _buildListWithoutHeaderFooter() {
    final effectivePadding = _getEffectivePadding();

    if (widget.gridDelegate != null) {
      // 网格布局
      return GridView.builder(
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        padding: effectivePadding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        // ignore: deprecated_member_use
        cacheExtent: _getCacheExtent(),
        gridDelegate: widget.gridDelegate!,
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
        shrinkWrap: widget.config._shrinkWrap,
      );
    } else if (widget.config._separatorBuilder != null) {
      // 带分隔线的列表
      return ListView.separated(
        itemBuilder: (context, index) => _buildItem(context, index),
        separatorBuilder: (context, index) => widget.config._separatorBuilder!(context, index),
        itemCount: widget.itemCount,
        padding: effectivePadding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        // ignore: deprecated_member_use
        cacheExtent: _getCacheExtent(),
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
        shrinkWrap: widget.config._shrinkWrap,
      );
    } else {
      // 普通列表
      return ListView.builder(
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        padding: effectivePadding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        // ignore: deprecated_member_use
        cacheExtent: _getCacheExtent(),
        itemExtent: _getEffectiveItemExtent(),
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
        shrinkWrap: widget.config._shrinkWrap,
      );
    }
  }

  /// 构建列表内容的 Sliver
  Widget _buildListSliver() {
    if (widget.gridDelegate != null) {
      // 网格布局
      return SliverGrid.builder(
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        gridDelegate: widget.gridDelegate!,
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    } else if (widget.config._separatorBuilder != null) {
      // 带分隔线的列表
      return SliverList.separated(
        itemBuilder: (context, index) => _buildItem(context, index),
        separatorBuilder: (context, index) => widget.config._separatorBuilder!(context, index),
        itemCount: widget.itemCount,
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    } else {
      // 普通列表
      final itemExtent = _getEffectiveItemExtent();
      if (itemExtent != null) {
        return SliverFixedExtentList(
          itemExtent: itemExtent,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildItem(context, index),
            childCount: widget.itemCount,
            addAutomaticKeepAlives: widget.cacheItems,
            addRepaintBoundaries: true,
            addSemanticIndexes: true,
          ),
        );
      }
      return SliverList.builder(
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        addAutomaticKeepAlives: widget.cacheItems,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.config.validate();
    assert(
      !widget.config._useOverlap || widget.gridDelegate == null,
      'useOverlap 不能与 gridDelegate 同时使用',
    );
    assert(
      !widget.config._useOverlap || widget.config._separatorBuilder == null,
      'useOverlap 不能与 separatorBuilder 同时使用',
    );
    assert(
      !widget.config._usePreciseCache || widget.cacheItems,
      'usePreciseCache 需要 cacheItems: true',
    );

    // 处理空列表情况
    // 优先使用组件参数，其次使用配置中的配置
    if (widget.itemCount == 0) {
      final emptyWidget = widget.emptyWidget ?? widget.config._emptyWidget;
      if (emptyWidget != null) {
        return emptyWidget;
      }
    }

    // 构建列表内容
    final listContent = _buildListContent();

    // 应用背景色、圆角和边框
    if (widget.config._backgroundColor != null ||
        widget.config._borderRadius != null ||
        widget.config._border != null) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.config._backgroundColor,
          borderRadius: widget.config._borderRadius,
          border: widget.config._border,
        ),
        child: listContent,
      );
    }

    return listContent;
  }

  /// 构建子项
  Widget _buildItem(BuildContext context, int index) {
    Widget item;
    if (widget.cacheItems) {
      if (widget.config._usePreciseCache) {
        // 精确缓存
        item = _PreciseCachedItemBuilder(
          index: index,
          builder: widget.itemBuilder,
        );
      } else {
        // 自动缓存
        item = AutomaticKeepAlive(
          child: widget.itemBuilder(context, index),
        );
      }
    } else {
      item = widget.itemBuilder(context, index);
    }

    // 如果启用了重叠效果，使用 OverflowBox 允许子项超出 itemExtent，然后向上偏移
    if (widget.config._useOverlap && widget.config._overlapOffset != 0.0) {
      item = OverflowBox(
        maxHeight: double.infinity, // 允许子项无限高度，避免底部裁剪
        alignment: Alignment.topCenter,
        child: item,
      );
    }

    return item;
  }
}

/// 缓存子项构建器
class _PreciseCachedItemBuilder extends StatefulWidget {
  final int index;
  final Widget Function(BuildContext, int) builder;

  const _PreciseCachedItemBuilder({required this.index, required this.builder});

  @override
  _PreciseCachedItemBuilderState createState() => _PreciseCachedItemBuilderState();
}

class _PreciseCachedItemBuilderState extends State<_PreciseCachedItemBuilder>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context, widget.index);
  }
}

/// 列表配置类
///
/// 用于配置 WListView 的各种行为和样式属性。
///
/// **配置参数说明:**
///
/// | 参数 | 类型 | 默认值 | 说明 |
/// |------|------|--------|------|
/// | `padding` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | 列表内边距 |
/// | `scrollDirection` | `Axis` | `Axis.vertical` | 滚动方向 |
/// | `reverse` | `bool` | `false` | 是否反向滚动 |
/// | `physics` | `ScrollPhysics` | `AlwaysScrollableScrollPhysics` | 物理滚动特性 |
/// | `cacheExtent` | `double?` | 垂直: 200, 水平: 100 | 预加载区域大小 |
/// | `itemExtent` | `double?` | `null` | 子项固定尺寸（高度/宽度） |
/// | `emptyWidget` | `Widget?` | `null` | 空列表占位符 |
/// | `usePreciseCache` | `bool` | `false` | 是否使用精确缓存机制 |
/// | `backgroundColor` | `Color?` | `null`（不绘制背景） | 背景色 |
/// | `borderRadius` | `BorderRadius?` | `null` | 圆角半径 |
/// | `border` | `BoxBorder?` | `null` | 边框 |
/// | `shrinkWrap` | `bool` | `false` | 是否自适应高度 |
/// | `separatorBuilder` | `Widget Function(BuildContext, int)?` | `null` | 分隔线构建器 |
/// | `useOverlap` | `bool` | `false` | 是否启用子项重叠效果 |
/// | `overlapOffset` | `double` | `0.0` | 重叠偏移量（必须 <= 0） |
///
/// **预设配置工厂方法:**
///
/// | 方法 | 说明 |
/// |------|------|
/// | `WListViewConfig()` | 默认配置 |
/// | `WListViewConfig.vertical()` | 垂直列表配置 |
/// | `WListViewConfig.horizontal()` | 水平列表配置 |
/// | `WListViewConfig.card()` | 卡片风格配置（白色背景、圆角） |
/// | `WListViewConfig.compact()` | 紧凑风格配置 |
///
/// **配置使用示例:**
///
/// ```dart
/// // 创建垂直列表配置
/// final config = WListViewConfig.vertical()
///   ..itemExtent = 60
///   ..padding = EdgeInsets.symmetric(horizontal: 16)
///   ..backgroundColor = Colors.white;
///
/// // 创建卡片风格配置并修改
/// final cardConfig = WListViewConfig.card()
///   ..borderRadius = BorderRadius.circular(12)
///   ..useOverlap = true
///   ..overlapOffset = -15;
///
/// // 复制配置并修改部分参数
/// final newConfig = config.copyWith(itemExtent: 80, shrinkWrap: true);
/// ```
class WListViewConfig {
  // 常量定义
  static const double _defaultVerticalCacheExtent = 200.0;
  static const double _defaultHorizontalCacheExtent = 100.0;
  static const double _defaultCompactCacheExtent = 150.0;
  static const EdgeInsets _defaultPadding = EdgeInsets.zero;
  static const EdgeInsets _defaultCardPadding = EdgeInsets.all(16.0);
  static const Color _defaultBackgroundColor = Colors.transparent;
  static const BorderRadius _defaultCardBorderRadius = BorderRadius.all(Radius.circular(8.0));

  /// 列表的内边距
  EdgeInsetsGeometry? _padding;

  /// 滚动方向
  Axis _scrollDirection = Axis.vertical;

  /// 是否反向滚动
  bool _reverse = false;

  /// 物理滚动特性
  ScrollPhysics? _physics;

  /// 缓存区域大小
  double? _cacheExtent;

  /// 子项的固定尺寸（高度或宽度，取决于滚动方向）
  double? _itemExtent;

  /// 空列表占位符
  Widget? _emptyWidget;

  /// 是否使用精确的缓存机制
  bool _usePreciseCache = false;

  /// 背景色
  Color? _backgroundColor;

  /// 圆角
  BorderRadius? _borderRadius;

  /// 边框
  BoxBorder? _border;

  /// 是否根据内容自动调整高度
  bool _shrinkWrap = false;

  /// 分隔线构建器
  Widget Function(BuildContext, int)? _separatorBuilder;

  /// 是否启用子项重叠效果
  bool _useOverlap = false;

  /// 子项重叠偏移量（负数表示向上重叠，必须小于等于0）
  double _overlapOffset = 0.0;

  /// 默认构造函数
  WListViewConfig() {
    _padding = EdgeInsets.zero;
    _physics = const AlwaysScrollableScrollPhysics();
    _cacheExtent = _defaultVerticalCacheExtent;
    _backgroundColor = _defaultBackgroundColor;
  }

  /// 设置列表的内边距
  set padding(EdgeInsetsGeometry value) {
    _padding = value;
  }

  /// 设置滚动方向
  set scrollDirection(Axis value) {
    _scrollDirection = value;
  }

  /// 设置是否反向滚动
  set reverse(bool value) {
    _reverse = value;
  }

  /// 设置物理滚动特性
  set physics(ScrollPhysics value) {
    _physics = value;
  }

  /// 设置缓存区域大小
  set cacheExtent(double? value) {
    _cacheExtent = value;
  }

  /// 设置子项的固定尺寸（高度或宽度，取决于滚动方向）
  set itemExtent(double value) {
    _itemExtent = value;
  }

  /// 设置空列表占位符
  set emptyWidget(Widget value) {
    _emptyWidget = value;
  }

  /// 设置是否使用精确的缓存机制
  set usePreciseCache(bool value) {
    _usePreciseCache = value;
  }

  /// 设置背景色
  set backgroundColor(Color value) {
    _backgroundColor = value;
  }

  /// 设置圆角
  set borderRadius(BorderRadius? value) {
    _borderRadius = value;
  }

  /// 设置边框
  set border(BoxBorder? value) {
    _border = value;
  }

  /// 设置是否根据内容自动调整高度
  set shrinkWrap(bool value) {
    _shrinkWrap = value;
  }

  /// 设置分隔线构建器
  set separatorBuilder(Widget Function(BuildContext, int)? value) {
    _separatorBuilder = value;
  }

  /// 设置是否启用子项重叠效果
  set useOverlap(bool value) {
    _useOverlap = value;
  }

  /// 设置子项重叠偏移量（负数表示向上重叠，必须小于等于0）
  ///
  /// - [value]：重叠偏移量，必须小于等于0，否则会被截断为0
  set overlapOffset(double value) {
    assert(value <= 0,
        'overlapOffset must be less than or equal to 0 (negative value means upward overlap)');
    _overlapOffset = value <= 0 ? value : 0;
  }

  /// 校验配置；在构建前暴露非法组合。
  void validate() {
    assert(
      !_useOverlap || (_itemExtent != null && _scrollDirection == Axis.vertical),
      'useOverlap 需要垂直列表和 itemExtent',
    );
    assert(
      _itemExtent == null || _itemExtent! > 0,
      'itemExtent 必须大于 0',
    );
  }

  /// 复制配置并返回新实例
  ///
  /// - [padding]：列表的内边距
  /// - [scrollDirection]：滚动方向
  /// - [reverse]：是否反向滚动
  /// - [physics]：物理滚动特性
  /// - [cacheExtent]：缓存区域大小
  /// - [itemExtent]：子项的固定尺寸（高度或宽度，取决于滚动方向）
  /// - [emptyWidget]：空列表占位符
  /// - [usePreciseCache]：是否使用精确的缓存机制
  /// - [backgroundColor]：背景色
  /// - [borderRadius]：圆角
  /// - [border]：边框
  /// - [shrinkWrap]：是否根据内容自动调整高度
  /// - [separatorBuilder]：分隔线构建器
  /// - [itemBuilderByT]：泛型子项构建器
  /// 返回：新的 WListViewConfig 实例
  WListViewConfig copyWith({
    EdgeInsetsGeometry? padding,
    Axis? scrollDirection,
    bool? reverse,
    ScrollPhysics? physics,
    double? cacheExtent,
    double? itemExtent,
    Widget? emptyWidget,
    bool? usePreciseCache,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
    bool? shrinkWrap,
    Widget Function(BuildContext, int)? separatorBuilder,
    Widget Function<T>(BuildContext, T)? itemBuilderByT,
    bool? useOverlap,
    double? overlapOffset,
  }) {
    final config = WListViewConfig();
    config._padding = padding ?? _padding;
    config._scrollDirection = scrollDirection ?? _scrollDirection;
    config._reverse = reverse ?? _reverse;
    config._physics = physics ?? _physics;
    config._cacheExtent = cacheExtent ?? _cacheExtent;
    config._itemExtent = itemExtent ?? _itemExtent;
    config._emptyWidget = emptyWidget ?? _emptyWidget;
    config._usePreciseCache = usePreciseCache ?? _usePreciseCache;
    config._backgroundColor = backgroundColor ?? _backgroundColor;
    config._borderRadius = borderRadius ?? _borderRadius;
    config._border = border ?? _border;
    config._shrinkWrap = shrinkWrap ?? _shrinkWrap;
    config._separatorBuilder = separatorBuilder ?? _separatorBuilder;
    config._itemBuilderByT = itemBuilderByT ?? _itemBuilderByT;
    config._useOverlap = useOverlap ?? _useOverlap;
    if (overlapOffset != null) {
      config.overlapOffset = overlapOffset;
    } else {
      config._overlapOffset = _overlapOffset;
    }
    config.validate();
    return config;
  }

  /// 复制配置
  ///
  /// 返回：新的 WListViewConfig 实例
  WListViewConfig copy() {
    return copyWith();
  }

  /// 创建配置的私有方法
  static WListViewConfig _createConfig({
    required Axis scrollDirection,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    double? cacheExtent,
    bool shrinkWrap = false,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    final config = WListViewConfig();
    config.scrollDirection = scrollDirection;
    config.padding = padding ?? _defaultPadding;
    config.physics = physics ?? const AlwaysScrollableScrollPhysics();
    config.cacheExtent = cacheExtent;
    config.shrinkWrap = shrinkWrap;
    config.backgroundColor = backgroundColor ?? _defaultBackgroundColor;
    config.borderRadius = borderRadius;
    config.border = border;
    return config;
  }

  /// 创建垂直列表配置
  factory WListViewConfig.vertical({
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    double? cacheExtent,
    bool shrinkWrap = false,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return _createConfig(
      scrollDirection: Axis.vertical,
      padding: padding,
      physics: physics,
      cacheExtent: cacheExtent ?? _defaultVerticalCacheExtent,
      shrinkWrap: shrinkWrap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
    );
  }

  /// 创建水平列表配置
  factory WListViewConfig.horizontal({
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    double? cacheExtent,
    bool shrinkWrap = false,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return _createConfig(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: physics,
      cacheExtent: cacheExtent ?? _defaultHorizontalCacheExtent,
      shrinkWrap: shrinkWrap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
    );
  }

  /// 创建卡片风格列表配置
  factory WListViewConfig.card({
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    double? cacheExtent,
    bool shrinkWrap = false,
    Color? backgroundColor = Colors.white,
    BorderRadius? borderRadius = _defaultCardBorderRadius,
    BoxBorder? border,
  }) {
    return _createConfig(
      scrollDirection: Axis.vertical,
      padding: padding ?? _defaultCardPadding,
      physics: physics,
      cacheExtent: cacheExtent ?? _defaultVerticalCacheExtent,
      shrinkWrap: shrinkWrap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
    );
  }

  /// 创建紧凑风格列表配置
  factory WListViewConfig.compact({
    EdgeInsetsGeometry? padding = _defaultPadding,
    ScrollPhysics? physics,
    double? cacheExtent,
    bool shrinkWrap = false,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return _createConfig(
      scrollDirection: Axis.vertical,
      padding: padding,
      physics: physics,
      cacheExtent: cacheExtent ?? _defaultCompactCacheExtent,
      shrinkWrap: shrinkWrap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
    );
  }

  /// 构建列表组件
  ///
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [controller]：列表控制器
  /// - [header]：列表头部
  /// - [footer]：列表尾部
  /// - [cacheItems]：是否启用子项缓存
  /// - [emptyWidget]：空列表占位符组件
  /// - [key]：组件键
  /// 返回：WListView 实例
  WListView build({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Widget? emptyWidget,
    Key? key,
  }) {
    return WListView(
      key: key,
      config: this,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      controller: controller,
      header: header,
      footer: footer,
      cacheItems: cacheItems,
      emptyWidget: emptyWidget,
    );
  }

  /// 泛型子项构建器（可选，预设构建器）
  Widget Function<T>(BuildContext, T)? _itemBuilderByT;

  /// 设置泛型子项构建器
  set itemBuilderByT(Widget Function<T>(BuildContext, T)? value) {
    _itemBuilderByT = value;
  }

  /// 根据数据列表构建列表组件（泛型版本）
  ///
  /// 这是一个便捷方法，直接接收数据列表并自动处理 itemCount。
  ///
  /// **使用方式:**
  ///
  /// ```dart
  /// // 方式1: 直接传入 itemBuilder
  /// final List<User> users = [...];
  /// WListViewConfig.vertical()
  ///   ..buildByList<User>(
  ///     data: users,
  ///     itemBuilder: (context, user) => ListTile(title: Text(user.name)),
  ///   );
  ///
  /// // 方式2: 预设 itemBuilderByT
  /// final config = WListViewConfig.vertical()
  ///   ..itemBuilderByT = (context, User user) => ListTile(title: Text(user.name));
  /// config.buildByList<User>(data: users);
  /// ```
  ///
  /// - [data]：数据列表
  /// - [itemBuilder]：子项构建器（优先级高于配置中的预设 itemBuilderByT）
  /// - [controller]：列表控制器
  /// - [header]：列表头部
  /// - [footer]：列表尾部
  /// - [cacheItems]：是否启用子项缓存
  /// - [emptyWidget]：空列表占位符组件（当 data 为空时显示）
  /// - [key]：组件键
  /// 返回：WListView 实例
  /// 抛出 [AssertionError]：如果 itemBuilder 和 itemBuilderByT 都为 null
  WListView buildByList<T>({
    required List<T> data,
    Widget Function(BuildContext, T)? itemBuilder,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Widget? emptyWidget,
    Key? key,
  }) {
    // 优先使用参数传入的构建器，其次使用配置中的预设
    final effectiveBuilder = itemBuilder ?? _itemBuilderByT;
    assert(effectiveBuilder != null, 'itemBuilder must be provided or itemBuilderByT must be set');

    Widget itemBuilderWrapper(BuildContext context, int index) {
      return effectiveBuilder!(context, data[index]);
    }

    return WListView(
      key: key,
      config: this,
      itemBuilder: itemBuilderWrapper,
      itemCount: data.length,
      controller: controller,
      header: header,
      footer: footer,
      cacheItems: cacheItems,
      emptyWidget: emptyWidget,
    );
  }

  /// 构建带有分隔线的列表组件
  ///
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [controller]：列表控制器
  /// - [header]：列表头部
  /// - [footer]：列表尾部
  /// - [cacheItems]：是否启用子项缓存
  /// - [emptyWidget]：空列表占位符组件
  /// - [key]：组件键
  /// 返回：WListView 实例
  WListView buildSeparated({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Widget? emptyWidget,
    Key? key,
  }) {
    return WListView.separated(
      key: key,
      config: this,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      controller: controller,
      header: header,
      footer: footer,
      cacheItems: cacheItems,
      emptyWidget: emptyWidget,
    );
  }

  /// 构建网格布局列表
  ///
  /// - [itemBuilder]：子项构建器
  /// - [itemCount]：子项数量
  /// - [gridDelegate]：网格布局代理
  /// - [controller]：列表控制器
  /// - [header]：列表头部
  /// - [footer]：列表尾部
  /// - [cacheItems]：是否启用子项缓存
  /// - [emptyWidget]：空列表占位符组件
  /// - [key]：组件键
  /// 返回：WListView 实例
  WListView buildGrid({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Widget? emptyWidget,
    Key? key,
  }) {
    return WListView.grid(
      key: key,
      config: this,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      controller: controller,
      header: header,
      footer: footer,
      cacheItems: cacheItems,
      emptyWidget: emptyWidget,
    );
  }
}
