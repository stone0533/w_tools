import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'log_support.dart' as log_support;

/// `WLogInterceptor` 内部使用的脱敏 / 格式化器。
///
/// 不对外导出；把 body 递归脱敏、URI 脱敏和截断从拦截器里分开，便于单测和
/// 后续替换实现。公开 API 仍然是 [WLogInterceptor]。
class WLogSanitizer {
  WLogSanitizer({
    required this.redactedHeaders,
    required this.sensitiveQueryKeys,
    required this.sensitiveBodyKeys,
    required this.maxBodyLength,
  });

  final Set<String> redactedHeaders;
  final Set<String> sensitiveQueryKeys;
  final Set<String> sensitiveBodyKeys;
  final int maxBodyLength;

  bool isRedactedHeader(String header) => redactedHeaders.contains(header.toLowerCase());

  Uri safeUri(Uri uri) => log_support.redactUri(uri, sensitiveQueryKeys);

  /// 格式化为可读文本：先按敏感 key 脱敏，Map/Iterable 走缩进 JSON，
  /// 二进制只输出字节数。
  String formatBody(dynamic value) {
    if (value is Uint8List) {
      return '<${value.length} bytes>';
    }
    final safe = _shrink(_redactBody(value));
    String text;
    if (safe is Map || safe is Iterable) {
      final encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      try {
        text = encoder.convert(safe);
      } catch (_) {
        text = safe.toString();
      }
    } else {
      text = safe.toString();
    }
    return _truncate(text);
  }

  /// 编码前按字符预算收紧 body，避免先构造一个超大 JSON 再截断。
  ///
  /// 只限制日志输出，不修改调用方原始 body；`maxBodyLength <= 0` 时保持
  /// “不截断”的旧语义。
  Object? _shrink(Object? value) {
    if (maxBodyLength <= 0) return value;
    return _shrinkValue(value, _CharBudget(maxBodyLength * 2), 0);
  }

  Object? _shrinkValue(Object? value, _CharBudget budget, int depth) {
    if (budget.exhausted) return '<truncated>';
    if (depth > 16) return '<truncated: too deep>';

    if (value is String) {
      final limit = budget.remaining;
      budget.consume(value.length);
      if (value.length <= limit) return value;
      var end = limit;
      if (end > 0) {
        final unit = value.codeUnitAt(end - 1);
        if (unit >= 0xD800 && unit <= 0xDBFF) end--;
      }
      return '${value.substring(0, end)}...';
    }

    if (value is Map) {
      final result = <dynamic, dynamic>{};
      var truncated = false;
      for (final entry in value.entries) {
        if (budget.exhausted) {
          truncated = true;
          break;
        }
        budget.consume(entry.key.toString().length);
        result[entry.key] = _shrinkValue(entry.value, budget, depth + 1);
      }
      if (truncated) {
        // 标记放最前面：后续 _truncate 从头部截断时仍能看到“已截断”。
        result.remove('...');
        return <dynamic, dynamic>{'...': '<truncated>', ...result};
      }
      return result;
    }

    if (value is Iterable) {
      final result = <dynamic>[];
      var truncated = false;
      for (final child in value) {
        if (budget.exhausted) {
          truncated = true;
          break;
        }
        result.add(_shrinkValue(child, budget, depth + 1));
      }
      if (truncated) {
        result.insert(0, '<truncated>');
      }
      return result;
    }

    return value;
  }

  /// 对 body 做递归脱敏；返回新对象，不修改调用方传入的 data。
  ///
  /// 覆盖 Map / List、JSON 字符串（以 `{` / `[` 开头）与 FormData fields；
  /// 任意对象的 `toString()` 无法可靠识别字段，保持原样。
  Object? _redactBody(dynamic value, {int depth = 0}) {
    if (depth > 16) return '<redacted: too deep>';
    if (value is FormData) {
      final fields = <String, String>{};
      for (final entry in value.fields) {
        fields[entry.key] = _isSensitiveBodyKey(entry.key) ? '***' : entry.value;
      }
      return <String, dynamic>{
        'fields': fields,
        'files': [
          for (final entry in value.files)
            <String, String>{
              'field': entry.key,
              'filename': entry.value.filename ?? '',
            },
        ],
      };
    }
    if (value is Map) {
      final result = <dynamic, dynamic>{};
      value.forEach((key, child) {
        result[key] = _isSensitiveBodyKey(key.toString())
            ? '***'
            : _redactBody(child, depth: depth + 1);
      });
      return result;
    }
    if (value is Iterable) {
      return <dynamic>[
        for (final child in value) _redactBody(child, depth: depth + 1),
      ];
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return value;
      // 0x7B = `{`，0x5B = `[`；不要写成字符串字面量，API 快照脚本按字符数花括号。
      final first = trimmed.codeUnitAt(0);
      if (first != 0x7B && first != 0x5B) return value;
      try {
        return _redactBody(jsonDecode(value), depth: depth + 1);
      } catch (_) {
        return value;
      }
    }
    return value;
  }

  bool _isSensitiveBodyKey(String key) => sensitiveBodyKeys.contains(key.toLowerCase());

  String _truncate(String text) {
    if (maxBodyLength <= 0 || text.length <= maxBodyLength) return text;
    var end = maxBodyLength;
    // 不要把代理对切成两半；截断点前是 high surrogate 时退一格。
    final unit = text.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end--;
    return '${text.substring(0, end)}\n'
        '... (truncated, ${text.length} chars)';
  }

  Object _toEncodableFallback(dynamic object) => object.toString();
}

class _CharBudget {
  _CharBudget(this.remaining);

  int remaining;

  bool get exhausted => remaining <= 0;

  void consume(int length) {
    remaining -= length;
  }
}
