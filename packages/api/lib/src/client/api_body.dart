import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 请求体描述。
///
/// ```dart
/// WApiBody.json({'name': 'Ada'});
/// WApiBody.form({'name': 'Ada'});
/// WApiBody.multipart(
///   fields: {'bucket': 'avatar'},
///   files: {'file': MultipartFile.fromBytes(bytes)},
/// );
/// WApiBody.bytes(bytes, contentType: 'application/octet-stream');
/// ```
class WApiBody {
  /// JSON body（Map / List / 可 jsonEncode 的值）。
  const WApiBody.json(Object? value) : data = value, contentType = Headers.jsonContentType;

  /// 表单 body；`null` 字段会被丢弃。
  WApiBody.form(Map<String, Object?> fields)
    : data = _withoutNulls(fields),
      contentType = Headers.formUrlEncodedContentType;

  /// multipart body；`null` 字段会被丢弃。
  ///
  /// [files] 的 key 是表单字段名（dio 5 的 `MultipartFile` 不再自带字段名）。
  WApiBody.multipart({
    Map<String, Object?> fields = const {},
    Map<String, MultipartFile> files = const {},
  }) : data = _formData(fields, files),
       contentType = null;

  /// 原始字节 body。
  WApiBody.bytes(List<int> bytes, {this.contentType}) : data = Uint8List.fromList(bytes);

  /// 直接传给 dio 的 `data`
  final Object? data;

  /// `Content-Type`；multipart 时为 null，由 dio 生成 boundary
  final String? contentType;

  static Map<String, Object?> _withoutNulls(Map<String, Object?> fields) => {
    for (final entry in fields.entries)
      if (entry.value != null) entry.key: entry.value,
  };

  static FormData _formData(
    Map<String, Object?> fields,
    Map<String, MultipartFile> files,
  ) {
    final form = FormData();
    for (final entry in _withoutNulls(fields).entries) {
      form.fields.add(MapEntry(entry.key, entry.value.toString()));
    }
    for (final entry in files.entries) {
      form.files.add(MapEntry(entry.key, entry.value));
    }
    return form;
  }
}
