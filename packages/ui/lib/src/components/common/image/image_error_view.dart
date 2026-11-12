import 'package:flutter/material.dart';

import '../../../internal/ui_strings.dart';
import 'image_types.dart';

const double _kActionMinWidth = 96;
const double _kActionMinHeight = 88;
const double _kTextMinHeightWithButton = 112;
const double _kTextMinHeight = 64;

/// 内置的错误占位：图标 + 文案 + 可选重试按钮。
///
/// 通过 `WImageSlots(showRetryButton: true)` 启用（`WImageStyle` 没有该参数）；
/// 业务也可以直接复用它。
class WImageErrorView extends StatelessWidget {
  const WImageErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = '',
    this.compact = false,
    this.showAction = true,
  });

  final WImageError error;
  final VoidCallback? onRetry;

  /// 重试按钮文案；空字符串表示按当前 `Locale` 使用内置文案
  /// （zh：重试；其他：Retry）。
  final String retryLabel;

  /// 小尺寸时只显示图标（不显示文案/按钮）
  final bool compact;

  /// 是否允许显示重试按钮（由外层按已知尺寸决定）
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
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
          // 小尺寸优先保留可操作的“重试”：空间不够时隐藏文案而不是隐藏按钮。
          final showButton =
              !compact &&
              showAction &&
              onRetry != null &&
              width >= _kActionMinWidth &&
              height >= _kActionMinHeight;
          final showText =
              !compact &&
              width >= _kActionMinWidth &&
              height >= (showButton ? _kTextMinHeightWithButton : _kTextMinHeight);

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
                      maxLines: showButton ? 1 : 2,
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
