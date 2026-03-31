import 'package:flutter/material.dart';

/// 步骤指示器配置类
class WStepConfig {
  /// 长度
  int? _length;

  /// 背景构建器
  Widget Function(Widget child)? _backgroundBuilder;

  /// 步骤项构建器
  Widget Function(int index, int current)? _itemBuilder;

  /// 分割线构建器
  Widget Function(int index, int current)? _dividerBuilder;

  /// 设置长度
  set length(int value) {
    _length = value;
  }

  /// 设置背景构建器
  set backgroundBuilder(Widget Function(Widget child)? value) {
    _backgroundBuilder = value;
  }

  /// 设置步骤项构建器
  set itemBuilder(Widget Function(int index, int current)? value) {
    _itemBuilder = value;
  }

  /// 设置分割线构建器
  set dividerBuilder(Widget Function(int index, int current)? value) {
    _dividerBuilder = value;
  }

  /// 构建步骤指示器组件
  WStep build({
    Key? key,
    int? index,
  }) {
    return WStep(
      key: key,
      config: this,
      index: index ?? 0,
    );
  }

  /// 创建当前配置的副本
  WStepConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  WStepConfig copyWith({
    int? length,
    Widget Function(Widget child)? backgroundBuilder,
    Widget Function(int index, int current)? itemBuilder,
    Widget Function(int index, int current)? dividerBuilder,
  }) {
    final config = WStepConfig();
    config._length = length ?? _length;
    config._backgroundBuilder = backgroundBuilder ?? _backgroundBuilder;
    config._itemBuilder = itemBuilder ?? _itemBuilder;
    config._dividerBuilder = dividerBuilder ?? _dividerBuilder;
    return config;
  }
}

/// 步骤指示器组件
class WStep extends StatelessWidget {
  /// 配置
  final WStepConfig config;

  /// 索引
  final int index;

  /// 创建步骤指示器
  const WStep({
    super.key,
    required this.config,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 缓存计算结果以提高性能
    final length = config._length;
    final backgroundBuilder = config._backgroundBuilder ?? ((child) => child);
    final itemBuilder = config._itemBuilder ?? _defaultItemBuilder;
    final dividerBuilder = config._dividerBuilder ?? _defaultDividerBuilder;

    List<Widget> children = [];

    // 构建步骤项和分割线
    if (length != null) {
      for (int i = 0; i < length; i++) {
        children.add(itemBuilder(i, index));
        if (i + 1 < length) {
          children.add(Expanded(child: dividerBuilder(i + 1, index)));
        }
      }
    }

    // 使用背景构建器包装
    return backgroundBuilder(Row(children: children));
  }

  /// 默认步骤项构建器
  Widget _defaultItemBuilder(int index, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: index <= currentIndex ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$index',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// 默认分割线构建器
  Widget _defaultDividerBuilder(int index, int currentIndex) {
    return Container(
      height: 2,
      color: index <= currentIndex ? Colors.blue : Colors.grey,
    );
  }
}
