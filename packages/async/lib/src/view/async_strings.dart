import 'package:flutter/foundation.dart';

/// UI 文案。
///
/// 默认使用中性英文；项目可通过 `WAsyncTheme(strings: ...)` 注入本地化文案。
@immutable
class WAsyncStrings {
  const WAsyncStrings({
    this.empty = 'No data',
    this.errorTitle = 'Something went wrong',
    this.retry = 'Retry',
  });

  final String empty;
  final String errorTitle;
  final String retry;

  @override
  bool operator ==(Object other) =>
      other is WAsyncStrings &&
      other.empty == empty &&
      other.errorTitle == errorTitle &&
      other.retry == retry;

  @override
  int get hashCode => Object.hash(empty, errorTitle, retry);
}
