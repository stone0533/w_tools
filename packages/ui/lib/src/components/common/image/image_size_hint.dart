import 'package:flutter/material.dart';

import 'image_source.dart';
import 'image_types.dart';

/// debug 下提示 WImage 在无界轴上的 0 尺寸占位。
///
/// 同一 source + 同一轴只提示一次；[debugResetWImageSizeHintCache] 供测试隔离。
void debugCheckWImageSizeHint(BuildContext context, {WImageSource? source}) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return;
  final constraints = renderObject.constraints;
  final size = renderObject.size;
  final unboundedWidth = constraints.maxWidth.isInfinite;
  final unboundedHeight = constraints.maxHeight.isInfinite;
  if (!unboundedWidth && !unboundedHeight) return;
  final zeroWidth = unboundedWidth && size.width <= 0;
  final zeroHeight = unboundedHeight && size.height <= 0;
  if (!zeroWidth && !zeroHeight) return;
  final axis = zeroWidth && zeroHeight ? '宽高' : (zeroWidth ? '宽度' : '高度');
  final key = '$axis:${source?.key ?? context.hashCode}';
  if (_warnedKeys.contains(key)) return;
  if (_warnedKeys.length > 200) _warnedKeys.clear();
  _warnedKeys.add(key);
  final sourceLabel = source == null ? '' : ' [source=${_sourceLabel(source)}]';
  debugPrint(
    '[w_tools_ui] WImage 在$axis轴上没有确定尺寸（加载前占位为 0，会表现为空白）。'
    '请给 WImageStyle 设置 width / height / aspectRatio，'
    '或让父级在$axis轴上有界（SizedBox / Expanded / AspectRatio）。'
    '$sourceLabel',
  );
}

/// 清空「已提示」缓存；仅测试使用，避免不同用例互相吞掉警告。
void debugResetWImageSizeHintCache() => _warnedKeys.clear();

final Set<String> _warnedKeys = <String>{};

String _sourceLabel(WImageSource source) {
  if (source.type == WImageType.base64) return '<base64>';
  var label = source.value;
  if (source.type == WImageType.network) {
    final uri = Uri.tryParse(label);
    if (uri != null && uri.hasScheme) {
      // 不把 query / fragment 里的 token 打进日志。
      label = uri.replace(query: '', fragment: '').toString().replaceFirst(RegExp(r'[?#]+$'), '');
    }
  }
  if (label.length > 120) {
    label = '${label.substring(0, 117)}...';
  }
  return label;
}
