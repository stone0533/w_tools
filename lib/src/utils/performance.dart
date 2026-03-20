import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 性能监控工具类
class WPerformance {
  /// 单例实例
  static final WPerformance _instance = WPerformance._internal();

  /// 性能数据集合
  final Map<String, List<PerformanceData>> _performanceData = {};

  /// 构造函数
  factory WPerformance() {
    return _instance;
  }

  /// 内部构造函数
  WPerformance._internal();

  /// 开始性能监控
  ///
  /// @param tag 监控标签
  /// @return 监控ID
  String start(String tag) {
    final id = _generateId();
    final data = PerformanceData(
      id: id,
      tag: tag,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );

    if (!_performanceData.containsKey(tag)) {
      _performanceData[tag] = [];
    }
    _performanceData[tag]!.add(data);

    return id;
  }

  /// 结束性能监控
  ///
  /// @param tag 监控标签
  /// @param id 监控ID
  /// @return 执行时间（毫秒）
  int end(String tag, String id) {
    final dataList = _performanceData[tag];
    if (dataList == null) {
      return -1;
    }

    final data = dataList.firstWhere(
      (item) => item.id == id,
      orElse: () => PerformanceData(id: '', tag: '', startTime: 0),
    );

    if (data.id.isEmpty) {
      return -1;
    }

    data.endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = data.endTime - data.startTime;

    // 打印性能数据
    if (kDebugMode) {
      print('Performance[$tag]: $duration ms');
    }

    // 发送性能数据到监控平台
    _reportPerformance(tag, duration);

    return duration;
  }

  /// 监控函数执行时间
  ///
  /// @param tag 监控标签
  /// @param function 要执行的函数
  /// @return 函数返回值
  Future<T> monitor<T>(String tag, Future<T> Function() function) async {
    final id = start(tag);
    try {
      return await function();
    } finally {
      end(tag, id);
    }
  }

  /// 监控同步函数执行时间
  ///
  /// @param tag 监控标签
  /// @param function 要执行的函数
  /// @return 函数返回值
  T monitorSync<T>(String tag, T Function() function) {
    final id = start(tag);
    try {
      return function();
    } finally {
      end(tag, id);
    }
  }

  /// 生成唯一ID
  String _generateId() {
    final random = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}';
  }

  /// 上报性能数据
  void _reportPerformance(String tag, int duration) {
    // 这里可以集成第三方监控平台，如 Firebase Performance Monitoring
    // 或者发送到自定义的监控服务器
    if (kDebugMode) {
      dev.log('Performance Report: $tag - $duration ms');
    }
  }

  /// 获取性能数据
  Map<String, List<PerformanceData>> get performanceData {
    return _performanceData;
  }

  /// 清空性能数据
  void clear() {
    _performanceData.clear();
  }
}

/// 性能数据类
class PerformanceData {
  /// 监控ID
  final String id;

  /// 监控标签
  final String tag;

  /// 开始时间
  final int startTime;

  /// 结束时间
  int endTime = 0;

  /// 构造函数
  PerformanceData({
    required this.id,
    required this.tag,
    required this.startTime,
  });

  /// 执行时间
  int get duration => endTime - startTime;

  @override
  String toString() {
    return 'PerformanceData{id: $id, tag: $tag, startTime: $startTime, endTime: $endTime, duration: $duration ms}';
  }
}
