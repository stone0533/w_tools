import 'package:flutter/widgets.dart';

import '../components/common/image/image_types.dart';

/// 内置 UI 文案（加载 / 重试 / 图片错误）。
///
/// 只按当前 `Locale` 在中文与英文之间选择；调用点的 `loadingLabel` /
/// `retryLabel` 仍可覆盖。需要第三种语言时，业务应在自己的 UI 层包一层
/// 自定义 [WImageSlots] / [WButtonSemantics]，而不是改这个内部实现。
@immutable
class WUiStrings {
  const WUiStrings({
    required this.loadingLabel,
    required this.retryLabel,
    required this.imageErrors,
  });

  final String loadingLabel;
  final String retryLabel;
  final Map<WImageErrorKind, String> imageErrors;

  String imageErrorMessage(WImageErrorKind kind) =>
      imageErrors[kind] ?? imageErrors[WImageErrorKind.provider]!;

  static const zh = WUiStrings(
    loadingLabel: '加载中',
    retryLabel: '重试',
    imageErrors: {
      WImageErrorKind.network: '网络图片加载失败',
      WImageErrorKind.asset: '本地资源加载失败',
      WImageErrorKind.decode: 'Base64 解码失败',
      WImageErrorKind.provider: '图片解码失败',
      WImageErrorKind.file: '本地文件读取失败',
      WImageErrorKind.unsupported: '当前平台不支持该图片源',
    },
  );

  static const en = WUiStrings(
    loadingLabel: 'Loading',
    retryLabel: 'Retry',
    imageErrors: {
      WImageErrorKind.network: 'Network image failed',
      WImageErrorKind.asset: 'Asset image failed',
      WImageErrorKind.decode: 'Base64 decode failed',
      WImageErrorKind.provider: 'Image decode failed',
      WImageErrorKind.file: 'File image failed',
      WImageErrorKind.unsupported: 'Unsupported image source',
    },
  );

  /// 按当前 Locale 取内置文案；非中文一律回退英文。
  static WUiStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode == 'zh' ? zh : en;
  }
}
