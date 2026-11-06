import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 解码后小于该字节数的 Base64 直接在主 isolate 解码。
const int imageBase64InlineThreshold = 64 * 1024;

Uint8List decodeImageBase64Sync(String data) => base64Decode(data);

/// 与 WImage / WImageSource.resolve 共用的 Base64 解码入口。
Future<Uint8List> decodeImageBase64(String data) {
  final estimatedBytes = data.length * 3 ~/ 4;
  if (estimatedBytes <= imageBase64InlineThreshold) {
    return Future<Uint8List>.sync(() => decodeImageBase64Sync(data));
  }
  return compute(decodeImageBase64Sync, data);
}
