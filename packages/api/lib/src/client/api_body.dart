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
  ///
  /// 省略 [contentType] 时该字段为 null；经 `WApiClient` 发送时，
  /// `Uint8List` body（含本构造器）会兜底成 `application/octet-stream`。
  /// 直接用 dio 发本实例时没有兜底，请显式传入；需要精确类型（图片 /
  /// protobuf / 文件）时也显式传入，或用 `headers: {'Content-Type': ...}` 覆盖。
  WApiBody.bytes(List<int> bytes, {this.contentType}) : data = Uint8List.fromList(bytes);

  /// 直接传给 dio 的 `data`
  final Object? data;

  /// `Content-Type`；multipart / bytes 省略时为 null（multipart 由 dio 生成
  /// boundary，bytes 由 `WApiClient` 兜底成 `application/octet-stream`）。
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
