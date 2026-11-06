import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_error_view.dart';
import 'image_frame.dart';
import 'image_loader.dart';
import 'image_notifier.dart';
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
/// 提供手动重试与加载状态：在 `errorWidget` 里放一个按钮调用 [retry] 可立即重新
/// 发起请求（不等自动重试的退避时间）；[state] 从创建起即可监听。
class WImageController {
  final ValueNotifier<WImageLoadSnapshot> _notifier =
      WImageDeferredValueNotifier<WImageLoadSnapshot>(const WImageLoadSnapshot());

  _WImageState? _state;
  WImageLoader? _loader;

  /// 是否已绑定到 [WImage]
  bool get isAttached => _state != null;

  /// 加载状态。
  ///
  /// 创建后即可监听（初始为 `idle`）；WImage 卸载后仍可安全监听/移除监听，
  /// 只是不再更新。不需要时调用 [dispose] 释放内部 notifier。
  ValueListenable<WImageLoadSnapshot> get state => _notifier;

  /// 手动重新加载
  ///
  /// 触发一次新的请求；组件未挂载时是空操作。
  void retry() => _loader?.retryNow();

  /// 释放 controller 持有的监听与 notifier。
  void dispose() {
    _loader?.state.removeListener(_sync);
    _loader = null;
    _state = null;
    _notifier.dispose();
  }

  /// @internal 由 _WImageState 调用
  void _attach(_WImageState state) {
    assert(
      _state == null || identical(_state, state),
      'WImageController 不能同时绑定多个 WImage；请为每张图使用独立 controller',
    );
    if (identical(_state, state)) return;
    _loader?.state.removeListener(_sync);
    _state = state;
    _loader = state.loader;
    _loader!.state.addListener(_sync);
    _sync();
  }

  /// @internal 由 _WImageState 调用
  void _detach(_WImageState state) {
    if (identical(_state, state)) {
      _loader?.state.removeListener(_sync);
      _state = null;
      _loader = null;
      // 保留 _notifier 的最后一个 snapshot：外部监听器仍然有效，只是不再更新。
    }
  }

  void _sync() {
    final loader = _loader;
    if (loader == null) return;
    _notifier.value = loader.state.value;
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

  /// 不可变加载行为配置
  final WImageLoadOptions config;

  /// 单图 UI 插槽；null 表示完全使用 `WImageTheme`
  final WImageSlots? slots;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 类型化的进度回调（网络图或带 chunk 的自定义 provider）
  final ValueChanged<WImageProgress>? onProgress;

  /// 图片控制器（手动重试）
  final WImageController? controller;

  /// 显式来源 + 不可变样式（推荐入口）
  factory WImage.source({
    Key? key,
    required WImageSource source,
    WImageStyle style = const WImageStyle(),
    WImageLoadOptions config = const WImageLoadOptions(),
    WImageSlots? slots,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage._(
      key: key,
      source: source,
      style: style,
      config: config,
      slots: slots,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  WImage._({
    super.key,
    required this.source,
    required this.style,
    required this.config,
    this.slots,
    this.onLoadStatusChanged,
    this.onProgress,
    this.controller,
  }) {
    style.validate();
    config.validate();
    slots?.validate();
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// WImage 的状态类
///
/// 类型判定与数据规范化只在 `initState` / `didUpdateWidget` 做一次，不再使用
/// 跨实例的全局缓存。
