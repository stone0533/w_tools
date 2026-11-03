import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;

/// 哈希工具类
///
/// 提供 MD5、SHA 系列、HMAC-SHA256 与加盐密码哈希。
/// MD5 / SHA1 已不适合安全场景，仅建议用于兼容或校验和。
class WHash {
  // 纯静态工具类，禁止实例化
  WHash._();

  /// 计算字符串的 MD5（十六进制小写）
  static String md5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = crypto.md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// 计算字节数据的 MD5（十六进制小写）
  ///
  /// 需要从文件计算时可配合 `File.readAsBytes()`：
  /// ```dart
  /// final hash = WHash.bytesMd5(await File(path).readAsBytes());
  /// ```
  static String bytesMd5(List<int> bytes) {
    final digest = crypto.md5.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// 计算字符串的 SHA1（十六进制小写）
  static String sha1(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha1.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// 计算字符串的 SHA256（十六进制小写）
  static String sha256(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha256.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// 计算字符串的 SHA512（十六进制小写）
  static String sha512(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha512.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// 计算 HMAC-SHA256（十六进制小写）
  static String hmacSha256(String data, String key) {
    final hmac = crypto.Hmac(crypto.sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return hex.encode(digest.bytes);
  }

  /// 密码哈希（加盐单轮 SHA-256）
  ///
  /// 返回格式为 `sha256$盐值$哈希值`；未传 [salt] 时随机生成。
  ///
}
