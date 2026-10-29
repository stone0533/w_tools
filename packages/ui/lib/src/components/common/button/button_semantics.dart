import 'package:flutter/foundation.dart';

/// 按钮语义与 loading 文案。
@immutable
class WButtonSemantics {
  const WButtonSemantics({
    this.label,
    this.hint,
    this.loadingLabel = '加载中',
  });

  final String? label;
  final String? hint;
  final String loadingLabel;

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
