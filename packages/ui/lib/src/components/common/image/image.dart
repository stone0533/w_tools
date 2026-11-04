import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_error_view.dart';
import 'image_frame.dart';
import 'image_loader.dart';
import 'image_source.dart';
import 'image_style.dart';
import 'image_config.dart';
import 'image_defaults.dart';
import 'image_types.dart';

import '_image_file_web.dart' if (dart.library.io) '_image_file_native.dart';

export 'image_frame.dart';
export 'image_error_view.dart';
export 'image_source.dart';
export 'image_style.dart';
export 'image_config.dart';
export 'image_defaults.dart';
export 'image_types.dart';

part 'image_state.dart';

/// 图片控制器
///
/// 一个 controller 只对应一张 WImage；同时绑定多张图会在 debug 下断言。
/// 目前只提供手动重试：在 `errorWidget` 里放一个按钮，点击调用 [retry]
/// 立即重新发起请求（不等自动重试的退避时间）。
class WImageController {
  _WImageState? _state;
  WImageLoader? _loader;
  ValueListenable<WImageLoadSnapshot>? _lastState;

  /// 是否已绑定到 [WImage]
  bool get isAttached => _state != null;

  /// 加载状态。
  ///
  /// 首次绑定后保持同一 [ValueListenable]；WImage 卸载后仍可安全监听/移除监听，
  /// 只是不再更新。
  ValueListenable<WImageLoadSnapshot>? get state => _loader?.state ?? _lastState;

  /// 手动重新加载
  ///
  /// 触发一次新的请求；组件未挂载时是空操作。
  void retry() => _loader?.retryNow();

  /// @internal 由 _WImageState 调用
  void _attach(_WImageState state) {
    assert(
      _state == null || identical(_state, state),
      'WImageController 不能同时绑定多个 WImage；请为每张图使用独立 controller',
    );
    if (identical(_state, state)) return;
    _state = state;
    _loader = state.loader;
    _lastState = _loader!.state;
  }

  /// @internal 由 _WImageState 调用
  void _detach(_WImageState state) {
    if (identical(_state, state)) {
      _state = null;
      _loader = null;
      // 保留 _lastState：外部持有的 ValueListenable 仍然有效，只是不再更新。
    }
  }
}

/// 图片组件
///
/// 统一使用 [WImage.source] + [WImageSource]；不再提供按字符串自动判定的旧构造器。
///
/// 提供占位符、错误处理、加载进度、网络重试（自动 + 手动）与图片变换
/// （圆角、边框、阴影、margin/padding）。
class WImage extends StatefulWidget {
  /// 图片来源
  final WImageSource source;

  /// 不可变视觉样式
  final WImageStyle style;

  /// 不可变加载配置
  final WImageLoadConfig config;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 类型化的进度回调（仅网络图片有值）
  final ValueChanged<WImageProgress>? onProgress;

  /// 图片控制器（手动重试）
  final WImageController? controller;

  /// 调用方传入的原始值（未 trim / 未规范化）
  String get data => source.raw;

  /// 显式类型；默认构造自动判定时为 null（历史语义）
  final WImageType? type;

  /// 显式来源 + 不可变样式（推荐入口）
  factory WImage.source({
    Key? key,
    required WImageSource source,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage._(
      key: key,
      type: source.type,
      source: source,
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  WImage._({
    super.key,
    required this.type,
    required this.source,
    required this.style,
    required this.config,
    this.onLoadStatusChanged,
    this.onProgress,
    this.controller,
  }) {
    style.validate();
    config.validate();
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// WImage 的状态类
///
/// 类型判定与数据规范化只在 `initState` / `didUpdateWidget` 做一次，不再使用
/// 跨实例的全局缓存。
