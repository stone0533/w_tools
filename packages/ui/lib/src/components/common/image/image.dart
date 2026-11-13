import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_frame.dart';
import '../../../internal/image_loader.dart';
import '../../../internal/image_notifier.dart';
import 'image_base64.dart';
import 'image_provider_factory.dart';
import 'image_size_hint.dart';
import 'image_slots_build.dart';
import 'image_slots_merge.dart';
import 'image_source.dart';
import 'image_style.dart';
import 'image_load_options.dart';
import 'image_slots.dart';
import 'image_theme.dart';
import 'image_types.dart';

export 'image_error_view.dart';
export 'image_source.dart';
export 'image_style.dart';
export 'image_load_options.dart';
export 'image_slots.dart';
export 'image_theme.dart';
export 'image_types.dart';

part 'image_state.dart';
part 'image_state_builders.dart';

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
  bool _disposed = false;

  /// 是否已绑定到 [WImage]
  bool get isAttached => _state != null;

  /// 加载状态。
  ///
  /// 创建后即可监听（初始为 `idle`）；WImage 卸载后仍可安全监听/移除监听，
  /// 只是不再更新。不需要时调用 [dispose] 释放内部 notifier。
  ValueListenable<WImageLoadSnapshot> get state => _notifier;

  /// 手动重新加载
  ///
  /// 触发一次新的请求；组件未挂载或 controller 已释放时是空操作。
  void retry() {
    if (_disposed) return;
    _loader?.retryNow();
  }

  /// 释放 controller 持有的监听与 notifier。
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loader?.state.removeListener(_sync);
    _loader = null;
    _state = null;
    _notifier.dispose();
  }

  /// @internal 由 _WImageState 调用
  void _attach(_WImageState state) {
    if (_disposed) {
      assert(!_disposed, 'WImageController 已 dispose，不能再绑定 WImage');
      return;
    }
    if (_state != null && !identical(_state, state)) {
      // release 下也报错：静默改绑会让第一张图的状态永久失联。
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError(
            'WImageController 不能同时绑定多个 WImage；请为每张图使用独立 controller',
          ),
          library: 'w_tools_ui',
          context: ErrorDescription('while attaching WImageController'),
        ),
      );
      return;
    }
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
    if (_disposed) return;
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
  final WImageLoadOptions options;

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
    WImageLoadOptions? options,
    WImageSlots? slots,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage._(
      key: key,
      source: source,
      style: style,
      options: options ?? const WImageLoadOptions(),
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
    required this.options,
    this.slots,
    this.onLoadStatusChanged,
    this.onProgress,
    this.controller,
  }) {
    style.validate();
    options.validate();
    slots?.validate();
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// WImage 的状态类
///
/// 类型判定与数据规范化只在 `initState` / `didUpdateWidget` 做一次，不再使用
/// 跨实例的全局缓存。
