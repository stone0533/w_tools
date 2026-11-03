import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
export 'image_cache_policy.dart';
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
/// 默认按 `data` 自动判定类型（网络 URL、本地资源、`file://` 路径、`data:` Base64）；
/// 需要确定性时用命名构造：[WImage.network] / [WImage.asset] / [WImage.file] /
/// [WImage.base64]，它们跳过判定，也不会被“看起来像 URL 的 asset 名”影响。
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

  /// 按字符串自动判定来源（便利入口；新代码建议用 [WImage.source]）
  factory WImage({
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    required String data,
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    assert(
      type != WImageType.provider,
      'provider 来源请使用 WImage.provider(...) / WImage.memory(...)',
    );
    return WImage._(
      key: key,
      type: type,
      source: WImageSource.parse(data, type: type),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

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

  /// 网络图片（`http` / `https`，或以 `//` 开头的协议相对地址）
  factory WImage.network(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    Map<String, String>? headers,
    String? cacheKey,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.network(data, headers: headers, cacheKey: cacheKey),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地资源图片（`assets/...` 或 `packages/<pkg>/...`）
  factory WImage.asset(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    String? package,
    bool prefix = false,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.asset(data, package: package, prefix: prefix),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 本地文件图片（带不带 `file://` 前缀都可以）
  factory WImage.file(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.file(data),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// Base64 图片（可以带 `data:...;base64,` 前缀，也可以直接给 Base64 串）
  factory WImage.base64(
    String data, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.base64(data),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 头像：正方形 + 全圆角。
  ///
  /// [style] 中显式给出的字段覆盖预设（尺寸、圆角仍保留），
  /// [size] 只在 [style] 没给 width/height 时生效。
  /// remove-in: 5.0.0
  @Deprecated('用 `WImage(data, style: WImageStyle.avatar(size))`；5.0 移除')
  factory WImage.avatar(
    String data, {
    Key? key,
    double size = 40,
    WImageStyle? style,
    WImageLoadConfig config = const WImageLoadConfig(),
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    // 预设是正方形：只覆盖宽度（未给高度）时仍保持正方形。
    var resolved = WImageStyle.avatar(size).merge(style);
    if (style?.height == null) {
      resolved = resolved.copyWith(height: resolved.width);
    }
    return WImage(
      key: key,
      data: data,
      type: type,
      style: resolved,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 缩略图：正方形 + 解码尺寸上限
  /// 缩略图：正方形 + 解码尺寸上限。
  ///
  /// [style] 中显式给出的字段覆盖预设；[width] / [height] 作为预设 fallback，
  /// 解码尺寸上限也按合并后的尺寸推导。
  /// remove-in: 5.0.0
  @Deprecated(
    '用 `WImage(data, style: WImageStyle.thumbnail(...), config: WImageLoadConfig(memCacheWidth: ...))`；5.0 移除',
  )
  factory WImage.thumbnail(
    String data, {
    Key? key,
    double width = 80,
    double? height,
    int? cacheSize,
    WImageStyle? style,
    WImageLoadConfig config = const WImageLoadConfig(),
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    var resolved = WImageStyle.thumbnail(width, height: height).merge(style);
    // 预设是正方形：只覆盖宽度（未给高度）时仍保持正方形。
    if (height == null && style?.height == null) {
      resolved = resolved.copyWith(height: resolved.width);
    }
    final resolvedWidth = resolved.width ?? width;
    final resolvedHeight = resolved.height ?? resolvedWidth;
    final defaultCache = cacheSize ?? (math.max(resolvedWidth, resolvedHeight) * 3).round();
    return WImage(
      key: key,
      data: data,
      type: type,
      style: resolved,
      config: config.copyWith(
        memCacheWidth: config.memCacheWidth ?? defaultCache,
        memCacheHeight: config.memCacheHeight ?? defaultCache,
      ),
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 封面图：固定比例 + 可选圆角。
  ///
  /// [style] 中显式给出的字段覆盖预设；[aspectRatio] / [radius] 作为 fallback。
  /// remove-in: 5.0.0
  @Deprecated('用 `WImage(data, style: WImageStyle.cover(...))`；5.0 移除')
  factory WImage.cover(
    String data, {
    Key? key,
    double? aspectRatio = 16 / 9,
    double? radius,
    WImageStyle? style,
    WImageLoadConfig config = const WImageLoadConfig(),
    WImageType? type,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage(
      key: key,
      data: data,
      type: type,
      style: WImageStyle.cover(aspectRatio: aspectRatio, radius: radius).merge(style),
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 资源图片：默认拼 `WAssets.imagePath`
  ///
  /// 兼容入口；新代码优先用 `WImage.asset(name, prefix: true)`。
  /// remove-in: 5.0.0
  @Deprecated('用 `WImage.asset(name, prefix: true)`；5.0 移除')
  factory WImage.assetImage(
    String name, {
    Key? key,
    String? package,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.asset(
      name,
      key: key,
      package: package,
      prefix: true,
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 任意 [ImageProvider]（高级入口）
  factory WImage.provider(
    ImageProvider provider, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.source(
      key: key,
      source: WImageSource.provider(provider),
      style: style,
      config: config,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }

  /// 内存字节（内部转成 `MemoryImage`）
  factory WImage.memory(
    Uint8List bytes, {
    Key? key,
    WImageStyle style = const WImageStyle(),
    WImageLoadConfig config = const WImageLoadConfig(),
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.provider(
      MemoryImage(bytes),
      key: key,
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
