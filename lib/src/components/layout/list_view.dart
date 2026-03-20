import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 增强版列表组件
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

  /// 下拉刷新回调
  final Future<void> Function()? onRefresh;

  /// 上拉加载更多回调
  final Future<void> Function()? onLoadMore;

  /// 错误回调
  final void Function(dynamic error)? onError;

  /// 刷新开始回调
  final void Function()? onRefreshStart;

  /// 刷新完成回调
  final void Function()? onRefreshComplete;

  /// 加载开始回调
  final void Function()? onLoadStart;

  /// 加载完成回调
  final void Function()? onLoadComplete;

  /// 是否有更多数据
  final bool hasMore;

  /// 网格布局代理
  final SliverGridDelegate? gridDelegate;

  /// 创建列表组件
  const WListView({
    super.key,
    required this.config,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.header,
    this.footer,
    this.cacheItems = false,
    this.onRefresh,
    this.onLoadMore,
    this.onError,
    this.onRefreshStart,
    this.onRefreshComplete,
    this.onLoadStart,
    this.onLoadComplete,
    this.hasMore = false,
    this.gridDelegate,
  });

  /// 创建带有分隔线的列表
  const WListView.separated({
    super.key,
    required this.config,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.header,
    this.footer,
    this.cacheItems = false,
    this.onRefresh,
    this.onLoadMore,
    this.onError,
    this.onRefreshStart,
    this.onRefreshComplete,
    this.onLoadStart,
    this.onLoadComplete,
    this.hasMore = false,
  }) : gridDelegate = null;

  /// 创建网格布局列表
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
    this.onRefresh,
    this.onLoadMore,
    this.onError,
    this.onRefreshStart,
    this.onRefreshComplete,
    this.onLoadStart,
    this.onLoadComplete,
    this.hasMore = false,
  });

  @override
  WListViewState createState() => WListViewState();
}

class WListViewState extends State<WListView> {
  late ScrollController _controller;
  RefreshController? _refreshController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    // 只在需要刷新或加载功能时初始化 _refreshController
    if (widget.onRefresh != null || widget.onLoadMore != null) {
      _refreshController = RefreshController(initialRefresh: false);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    // 只在初始化了 _refreshController 时才释放
    _refreshController?.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    if (widget.onRefreshStart != null) {
      widget.onRefreshStart!();
    }
    if (widget.onRefresh != null) {
      try {
        await widget.onRefresh!();
        _refreshController?.refreshCompleted();
        _refreshController?.resetNoData();
        if (widget.onRefreshComplete != null) {
          widget.onRefreshComplete!();
        }
      } catch (e) {
        _refreshController?.refreshFailed();
        if (widget.onError != null) {
          widget.onError!(e);
        }
      }
    } else {
      _refreshController?.refreshCompleted();
      _refreshController?.resetNoData();
      if (widget.onRefreshComplete != null) {
        widget.onRefreshComplete!();
      }
    }
  }

  void _onLoading() async {
    if (widget.onLoadStart != null) {
      widget.onLoadStart!();
    }
    if (widget.onLoadMore != null && widget.hasMore) {
      try {
        await widget.onLoadMore!();
        _refreshController?.loadComplete();
        if (widget.onLoadComplete != null) {
          widget.onLoadComplete!();
        }
      } catch (e) {
        _refreshController?.loadFailed();
        if (widget.onError != null) {
          widget.onError!(e);
        }
      }
    } else {
      _refreshController?.loadNoData();
      if (widget.onLoadComplete != null) {
        widget.onLoadComplete!();
      }
    }
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
    return widget.config._cacheExtent ?? (widget.config._scrollDirection == Axis.vertical ? WListViewConfig._defaultVerticalCacheExtent : WListViewConfig._defaultHorizontalCacheExtent);
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
    return CustomScrollView(
      key: widget.key,
      slivers: slivers,
      controller: _controller,
      scrollDirection: widget.config._scrollDirection,
      reverse: widget.config._reverse,
      physics: widget.config._physics,
      cacheExtent: _getCacheExtent(),
      shrinkWrap: widget.config._shrinkWrap,
    );
  }

  /// 构建不带头部和尾部的列表
  Widget _buildListWithoutHeaderFooter() {
    if (widget.gridDelegate != null) {
      // 网格布局
      return GridView.builder(
        key: widget.key,
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        padding: widget.config._padding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        cacheExtent: _getCacheExtent(),
        gridDelegate: widget.gridDelegate!,
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
        shrinkWrap: widget.config._shrinkWrap,
      );
    } else if (widget.config._separatorBuilder != null) {
      // 带分隔线的列表
      return ListView.separated(
        key: widget.key,
        itemBuilder: (context, index) => _buildItem(context, index),
        separatorBuilder: (context, index) => widget.config._separatorBuilder!(context, index),
        itemCount: widget.itemCount,
        padding: widget.config._padding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        cacheExtent: _getCacheExtent(),
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
        shrinkWrap: widget.config._shrinkWrap,
      );
    } else {
      // 普通列表
      return ListView.builder(
        key: widget.key,
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        padding: widget.config._padding,
        controller: _controller,
        scrollDirection: widget.config._scrollDirection,
        reverse: widget.config._reverse,
        physics: widget.config._physics,
        cacheExtent: _getCacheExtent(),
        itemExtent: widget.config._itemExtent,
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
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
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    } else if (widget.config._separatorBuilder != null) {
      // 带分隔线的列表
      return SliverList.separated(
        itemBuilder: (context, index) => _buildItem(context, index),
        separatorBuilder: (context, index) => widget.config._separatorBuilder!(context, index),
        itemCount: widget.itemCount,
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    } else {
      // 普通列表
      return SliverList.builder(
        itemBuilder: (context, index) => _buildItem(context, index),
        itemCount: widget.itemCount,
        addAutomaticKeepAlives: widget.cacheItems && !widget.config._usePreciseCache,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 处理空列表情况
    if (widget.itemCount == 0 && widget.config._emptyWidget != null) {
      return widget.config._emptyWidget!;
    }

    // 构建列表内容
    final listContent = _buildListContent();

    // 只在需要刷新或加载功能时使用 SmartRefresher
    Widget result;
    if (widget.onRefresh != null || widget.onLoadMore != null) {
      result = SmartRefresher(
        enablePullDown: widget.onRefresh != null,
        enablePullUp: widget.onLoadMore != null,
        controller: _refreshController!,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: widget.config._refreshHeader,
        footer: widget.config._refreshFooter,
        scrollDirection: widget.config._scrollDirection,
        child: listContent,
      );
    } else {
      result = listContent;
    }

    // 应用背景色、圆角和边框
    if (widget.config._backgroundColor != null || widget.config._borderRadius != null || widget.config._border != null) {
      return Container(
        decoration: BoxDecoration(
          color: widget.config._backgroundColor,
          borderRadius: widget.config._borderRadius,
          border: widget.config._border,
        ),
        child: result,
      );
    }

    return result;
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
    
    return item;
  }

  /// 刷新列表
  void refresh() {
    setState(() {});
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

class _PreciseCachedItemBuilderState extends State<_PreciseCachedItemBuilder> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context, widget.index);
  }
}

/// 列表配置类
class WListViewConfig {
  // 常量定义
  static const double _defaultVerticalCacheExtent = 200.0;
  static const double _defaultHorizontalCacheExtent = 100.0;
  static const double _defaultCompactCacheExtent = 150.0;
  static const EdgeInsets _defaultPadding = EdgeInsets.zero;
  static const EdgeInsets _defaultCardPadding = EdgeInsets.all(16.0);
  static const Color _defaultBackgroundColor = Colors.transparent;
  static const BorderRadius _defaultCardBorderRadius = BorderRadius.all(Radius.circular(8.0));

  /// 子项间隔
  EdgeInsetsGeometry? _padding;

  /// 滚动方向
  Axis _scrollDirection = Axis.vertical;

  /// 是否反向滚动
  bool _reverse = false;

  /// 物理滚动特性
  ScrollPhysics? _physics;

  /// 缓存区域大小
  double? _cacheExtent;

  /// 子项之间的间距
  double? _itemExtent;

  /// 空列表占位符
  Widget? _emptyWidget;

  /// 是否使用精确的缓存机制
  bool _usePreciseCache = false;

  /// 刷新头部
  Widget? _refreshHeader;

  /// 刷新尾部
  Widget? _refreshFooter;

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

  /// 默认构造函数
  WListViewConfig() {
    _padding = EdgeInsets.zero;
  }

  /// 设置子项间隔
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

  /// 设置子项之间的间距
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

  /// 设置刷新头部
  set refreshHeader(Widget value) {
    _refreshHeader = value;
  }

  /// 设置刷新尾部
  set refreshFooter(Widget value) {
    _refreshFooter = value;
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

  /// 复制配置并返回新实例
  ///
  /// @param padding 子项间隔
  /// @param scrollDirection 滚动方向
  /// @param reverse 是否反向滚动
  /// @param physics 物理滚动特性
  /// @param cacheExtent 缓存区域大小
  /// @param itemExtent 子项之间的间距
  /// @param emptyWidget 空列表占位符
  /// @param usePreciseCache 是否使用精确的缓存机制
  /// @param refreshHeader 刷新头部
  /// @param refreshFooter 刷新尾部
  /// @param backgroundColor 背景色
  /// @param borderRadius 圆角
  /// @param border 边框
  /// @param shrinkWrap 是否根据内容自动调整高度
  /// @param separatorBuilder 分隔线构建器
  /// @return 新的 WListViewConfig 实例
  WListViewConfig copyWith({
    EdgeInsetsGeometry? padding,
    Axis? scrollDirection,
    bool? reverse,
    ScrollPhysics? physics,
    double? cacheExtent,
    double? itemExtent,
    Widget? emptyWidget,
    bool? usePreciseCache,
    Widget? refreshHeader,
    Widget? refreshFooter,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
    bool? shrinkWrap,
    Widget Function(BuildContext, int)? separatorBuilder,
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
    config._refreshHeader = refreshHeader ?? _refreshHeader;
    config._refreshFooter = refreshFooter ?? _refreshFooter;
    config._backgroundColor = backgroundColor ?? _backgroundColor;
    config._borderRadius = borderRadius ?? _borderRadius;
    config._border = border ?? _border;
    config._shrinkWrap = shrinkWrap ?? _shrinkWrap;
    config._separatorBuilder = separatorBuilder ?? _separatorBuilder;
    return config;
  }

  /// 复制配置
  ///
  /// @return 新的 WListViewConfig 实例
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
  /// @param itemBuilder 子项构建器
  /// @param itemCount 子项数量
  /// @param controller 列表控制器
  /// @param header 列表头部
  /// @param footer 列表尾部
  /// @param cacheItems 是否启用子项缓存
  /// @param onRefresh 下拉刷新回调
  /// @param onLoadMore 上拉加载更多回调
  /// @param onError 错误回调
  /// @param onRefreshStart 刷新开始回调
  /// @param onRefreshComplete 刷新完成回调
  /// @param onLoadStart 加载开始回调
  /// @param onLoadComplete 加载完成回调
  /// @param hasMore 是否有更多数据
  /// @param key 组件键
  /// @return WListView 实例
  WListView build({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Future<void> Function()? onRefresh,
    Future<void> Function()? onLoadMore,
    void Function(dynamic error)? onError,
    void Function()? onRefreshStart,
    void Function()? onRefreshComplete,
    void Function()? onLoadStart,
    void Function()? onLoadComplete,
    bool hasMore = false,
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
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      onError: onError,
      onRefreshStart: onRefreshStart,
      onRefreshComplete: onRefreshComplete,
      onLoadStart: onLoadStart,
      onLoadComplete: onLoadComplete,
      hasMore: hasMore,
    );
  }

  /// 泛型子项构建器
  Widget Function<T>(BuildContext, T)? _itemBuilderByT;

  /// 设置泛型子项构建器
  set itemBuilderByT(Widget Function<T>(BuildContext, T)? value) {
    _itemBuilderByT = value;
  }

  /// 根据数据列表构建列表组件
  ///
  /// @param data 数据列表
  /// @param controller 列表控制器
  /// @param header 列表头部
  /// @param footer 列表尾部
  /// @param cacheItems 是否启用子项缓存
  /// @param onRefresh 下拉刷新回调
  /// @param onLoadMore 上拉加载更多回调
  /// @param onError 错误回调
  /// @param onRefreshStart 刷新开始回调
  /// @param onRefreshComplete 刷新完成回调
  /// @param onLoadStart 加载开始回调
  /// @param onLoadComplete 加载完成回调
  /// @param hasMore 是否有更多数据
  /// @param key 组件键
  /// @return WListView 实例
  WListView buildByList<T>({
    required List<T> data,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Future<void> Function()? onRefresh,
    Future<void> Function()? onLoadMore,
    void Function(dynamic error)? onError,
    void Function()? onRefreshStart,
    void Function()? onRefreshComplete,
    void Function()? onLoadStart,
    void Function()? onLoadComplete,
    bool hasMore = false,
    Key? key,
  }) {
    assert(_itemBuilderByT != null, 'itemBuilderByT must be set before calling buildByList');
    
    Widget itemBuilder(BuildContext context, int index) {
      return _itemBuilderByT!(context, data[index]);
    }
    
    return WListView(
      key: key,
      config: this,
      itemBuilder: itemBuilder,
      itemCount: data.length,
      controller: controller,
      header: header,
      footer: footer,
      cacheItems: cacheItems,
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      onError: onError,
      onRefreshStart: onRefreshStart,
      onRefreshComplete: onRefreshComplete,
      onLoadStart: onLoadStart,
      onLoadComplete: onLoadComplete,
      hasMore: hasMore,
    );
  }

  /// 构建带有分隔线的列表组件
  ///
  /// @param itemBuilder 子项构建器
  /// @param itemCount 子项数量
  /// @param controller 列表控制器
  /// @param header 列表头部
  /// @param footer 列表尾部
  /// @param cacheItems 是否启用子项缓存
  /// @param onRefresh 下拉刷新回调
  /// @param onLoadMore 上拉加载更多回调
  /// @param onError 错误回调
  /// @param onRefreshStart 刷新开始回调
  /// @param onRefreshComplete 刷新完成回调
  /// @param onLoadStart 加载开始回调
  /// @param onLoadComplete 加载完成回调
  /// @param hasMore 是否有更多数据
  /// @param key 组件键
  /// @return WListView 实例
  WListView buildSeparated({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Future<void> Function()? onRefresh,
    Future<void> Function()? onLoadMore,
    void Function(dynamic error)? onError,
    void Function()? onRefreshStart,
    void Function()? onRefreshComplete,
    void Function()? onLoadStart,
    void Function()? onLoadComplete,
    bool hasMore = false,
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
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      onError: onError,
      onRefreshStart: onRefreshStart,
      onRefreshComplete: onRefreshComplete,
      onLoadStart: onLoadStart,
      onLoadComplete: onLoadComplete,
      hasMore: hasMore,
    );
  }

  /// 构建网格布局列表
  ///
  /// @param itemBuilder 子项构建器
  /// @param itemCount 子项数量
  /// @param gridDelegate 网格布局代理
  /// @param controller 列表控制器
  /// @param header 列表头部
  /// @param footer 列表尾部
  /// @param cacheItems 是否启用子项缓存
  /// @param onRefresh 下拉刷新回调
  /// @param onLoadMore 上拉加载更多回调
  /// @param onError 错误回调
  /// @param onRefreshStart 刷新开始回调
  /// @param onRefreshComplete 刷新完成回调
  /// @param onLoadStart 加载开始回调
  /// @param onLoadComplete 加载完成回调
  /// @param hasMore 是否有更多数据
  /// @param key 组件键
  /// @return WListView 实例
  WListView buildGrid({
    required Widget Function(BuildContext, int) itemBuilder,
    required int itemCount,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    Widget? header,
    Widget? footer,
    bool cacheItems = false,
    Future<void> Function()? onRefresh,
    Future<void> Function()? onLoadMore,
    void Function(dynamic error)? onError,
    void Function()? onRefreshStart,
    void Function()? onRefreshComplete,
    void Function()? onLoadStart,
    void Function()? onLoadComplete,
    bool hasMore = false,
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
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      onError: onError,
      onRefreshStart: onRefreshStart,
      onRefreshComplete: onRefreshComplete,
      onLoadStart: onLoadStart,
      onLoadComplete: onLoadComplete,
      hasMore: hasMore,
    );
  }

}







