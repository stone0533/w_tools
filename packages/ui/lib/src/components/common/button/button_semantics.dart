import 'package:flutter/foundation.dart';

/// 按钮语义与 loading 文案。
@immutable
class WButtonSemantics {
  const WButtonSemantics({
    this.label,
    this.hint,
    this.loadingLabel = '',
  });

  final String? label;
  final String? hint;

  /// loading 时的读屏文案。
  ///
  /// 空字符串表示按当前 `Locale` 使用内置文案（zh：加载中；其他：Loading）；
  /// 传非空字符串则完全使用调用方文案。
  final String loadingLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WButtonSemantics &&
          other.label == label &&
          other.hint == hint &&
          other.loadingLabel == loadingLabel;

  @override
  int get hashCode => Object.hash(label, hint, loadingLabel);

  WButtonSemantics copyWith({
    String? label,
    String? hint,
    String? loadingLabel,
  }) {
    return WButtonSemantics(
      label: label ?? this.label,
      hint: hint ?? this.hint,
      loadingLabel: loadingLabel ?? this.loadingLabel,
    );
  }

  /// 清空 label。
  WButtonSemantics withoutLabel() => WButtonSemantics(hint: hint, loadingLabel: loadingLabel);

  /// 清空 hint。
  WButtonSemantics withoutHint() => WButtonSemantics(label: label, loadingLabel: loadingLabel);
}
