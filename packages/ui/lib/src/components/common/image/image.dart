import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_frame.dart';
import '../../../internal/image_loader.dart';
import 'image_base64.dart';
import 'image_provider_factory.dart';
import 'image_size_hint.dart';
import 'image_slots_build.dart';
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

/// 图片组件
///
/// 统一使用 [WImage.source] + [WImageSource]；不再提供按字符串自动判定的旧构造器。
///
/// 提供占位、错误处理、进度回调与网络自动重试；手动重试通过
/// `WImageSlots.errorWidgetBuilder` 的 `onRetry` 参数触发。
/// 视觉（尺寸 / 圆角 / 边框 / 阴影）与布局 padding 分离：需要留白时在外部包
/// `Padding` / `Container`。
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

  /// 显式来源 + 不可变样式（推荐入口）
  factory WImage.source({
    Key? key,
    required WImageSource source,
    WImageStyle style = const WImageStyle(),
    WImageLoadOptions? options,
    WImageSlots? slots,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
  }) {
    return WImage._(
      key: key,
      source: source,
      style: style,
      options: options ?? const WImageLoadOptions(),
      slots: slots,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
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
  }) {
    style.validate();
    options.validate();
  }

  @override
  State<WImage> createState() => _WImageState();
}

/// WImage 的状态类
///
/// 类型判定与数据规范化只在 `initState` / `didUpdateWidget` 做一次，不再使用
/// 跨实例的全局缓存。
