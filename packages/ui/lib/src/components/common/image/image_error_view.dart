import 'package:flutter/material.dart';

import '../../../internal/ui_strings.dart';
import 'image_types.dart';

/// 文案 / 操作按钮各自需要的最小高度；低于该高度只显示图标，避免溢出。
const double _kTextMinHeight = 64;
const double _kActionMinHeight = 88;

/// 现成的「错误 + 重试」占位。
///
/// 在 `WImageSlots.errorWidgetBuilder` 里返回它，并把 builder 收到的 `onRetry`
/// 传进来即可：
///
/// ```dart
/// slots: WImageSlots(
///   errorWidgetBuilder: (context, data, error, retry) =>
///       WImageErrorView(error: error, onRetry: retry),
/// )
/// ```
///
/// 是否显示重试按钮由 [showAction] 与可用高度共同决定。
class WImageErrorView extends StatelessWidget {
  const WImageErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = '',
    this.showAction = true,
  });

  final WImageError error;
  final VoidCallback? onRetry;

  /// 重试按钮文案；空字符串表示按当前 `Locale` 使用内置文案
  /// （zh：重试；其他：Retry）。
  final String retryLabel;

  /// 是否允许显示重试按钮；高度不足时仍会自动隐藏。
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = WUiStrings.of(context);
    final retryText = retryLabel.isEmpty ? strings.retryLabel : retryLabel;
    return ColoredBox(
      color: colors.errorContainer.withValues(alpha: 0.35),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
          final showButton = showAction && onRetry != null && height >= _kActionMinHeight;
          final showText = height >= _kTextMinHeight;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: colors.error),
                  if (showText) ...[
                    const SizedBox(height: 4),
                    Text(
                      strings.imageErrorMessage(error.kind),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (showButton) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(retryText),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
