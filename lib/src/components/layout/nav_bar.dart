import 'package:flutter/material.dart';
import 'container.dart';
import 'nav_controller.dart';

class WNavBar extends StatefulWidget {
  /// 标签栏配置
  final WNavBarConfig config;
  /// 导航项构建器
  final Widget Function(BuildContext, int, bool) itemBuilder;
  /// 导航项点击回调
  final Future<bool?>? Function(int)? onItemTap;
  /// 导航栏控制器
  final WNavController controller;
  /// 提供 vsync
  final TickerProvider? vsync;
  const WNavBar({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.onItemTap,
    required this.controller,
    this.vsync,
  });

  @override
  State<WNavBar> createState() => _WNavBarState();
}

class _WNavBarState extends State<WNavBar> with TickerProviderStateMixin {
  late WNavController _controller;
  final Map<int, Widget> _itemCache = {};
  static const int _maxCacheSize = 5; // 限制缓存大小
  int _previousIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _previousIndex = _controller.currentIndex;
    _controller.addListener(() {
      // 当选中索引变化时，清除缓存的选中项
      if (_previousIndex != -1 && _previousIndex != _controller.currentIndex) {
        _itemCache.remove(_previousIndex);
        // 清理超出限制的缓存
        if (_itemCache.length > _maxCacheSize) {
          final keys = _itemCache.keys.toList();
          for (int i = 0; i < _itemCache.length - _maxCacheSize; i++) {
            _itemCache.remove(keys[i]);
          }
        }
      }
      _previousIndex = _controller.currentIndex;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建导航项内容
    Widget navContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < _controller.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await widget.onItemTap?.call(i);
                if (result != false) {
                  _controller.animateTo(i);
                }
              },
              child: RepaintBoundary(
                child: _buildNavItem(i),
              ),
            ),
          ),
      ],
    );
    
    // 如果提供了容器配置，使用配置中的构建器
    if (widget.config._containerConfig != null) {
      return widget.config._containerConfig!.build(child: navContent);
    }
    
    // 默认直接返回导航内容
    return navContent;
  }

  Widget _buildNavItem(int index) {
    bool isSelected = index == _controller.currentIndex;
    // 每次都重新构建，确保选中状态正确
    _itemCache[index] = widget.itemBuilder(context, index, isSelected);
    return _itemCache[index]!;
  }
}

class WNavBarConfig {
  WContainerConfig? _containerConfig;

  set containerConfig(WContainerConfig? value) {
    _containerConfig = value;
  }

  /// 构建导航栏
  WNavBar build({
    required Widget Function(BuildContext, int, bool) itemBuilder,
    Future<bool?>? Function(int)? onItemTap,
    required WNavController controller,
  }) {
    return WNavBar(
      config: this,
      itemBuilder: itemBuilder,
      onItemTap: onItemTap,
      controller: controller,
    );
  }
}


