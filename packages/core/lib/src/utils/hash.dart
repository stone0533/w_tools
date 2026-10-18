import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:math';

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
  /// 注意：单轮 SHA-256 属于快速哈希，仅适用于轻量场景，不适用于高安全
  /// 要求的密码存储；高安全场景请使用 bcrypt / Argon2 等慢哈希算法。
  static String hashPassword(String password, {String? salt}) {
    final saltStr = salt ?? _generateRandomSalt();
    final combined = '$password$saltStr';
    final hash = sha256(combined);
    return 'sha256\$$saltStr\$$hash';
  }

  /// 校验密码是否与 [hash] 匹配
  ///
  /// [hash] 格式不合法（不是 `算法$盐值$哈希值` 三段式）时返回 false。
  static bool verifyPassword(String password, String hash) {
    final parts = hash.split('\$');
    if (parts.length != 3) {
      return false;
    }

    final salt = parts[1];
    final expectedHash = parts[2];
    final computedHash = hashPassword(password, salt: salt);
    final computedHashParts = computedHash.split('\$');

    return computedHashParts[2] == expectedHash;
  }

  /// 生成 16 字节随机盐（Base64 编码）
  static String _generateRandomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
