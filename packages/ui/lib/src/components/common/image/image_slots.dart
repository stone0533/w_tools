import 'package:flutter/widgets.dart';

import 'image_types.dart';

/// 图片加载 UI 的两个插槽：占位与错误。
///
/// [WImage] 可以传一份单图 slots；`WImageTheme` 提供 App 级默认值。
/// 单图未给出的字段按字段回退到主题，再回退到内置兜底。
///
/// - 空 data（`''` / 纯空白）、加载中、等待重试都走 [placeholderBuilder]；
/// - 需要进度百分比时在 [placeholderBuilder] 里自己读 `WImage.onProgress`；
/// - 需要「错误 + 重试」时在 [errorWidgetBuilder] 里组合 `WImageErrorView`，
///   它的 [onRetry] 参数会重新发起加载。
@immutable
class WImageSlots {
  const WImageSlots({
    this.placeholderBuilder,
    this.errorWidgetBuilder,
  });

  /// 占位 UI：空数据 / 加载中 / 自动重试等待。
  final Widget? Function(BuildContext context, String data)? placeholderBuilder;

  /// 错误占位；[onRetry] 重新发起一次加载（组件未挂载时是空操作）。
  final Widget? Function(
    BuildContext context,
    String data,
    WImageError error,
    VoidCallback onRetry,
  )?
  errorWidgetBuilder;

  @override
  bool operator ==(Object other) =>
      other is WImageSlots &&
      other.placeholderBuilder == placeholderBuilder &&
      other.errorWidgetBuilder == errorWidgetBuilder;

  @override
  int get hashCode => Object.hash(placeholderBuilder, errorWidgetBuilder);
}
