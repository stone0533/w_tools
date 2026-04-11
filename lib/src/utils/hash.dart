import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:io';
import 'dart:math';

/// 哈希工具类，提供各种哈希功能
///
/// 该类封装了常用的哈希算法，包括 MD5、SHA 系列、HMAC-SHA256 以及密码哈希功能
class WHash {
  /// MD5 哈希
  ///
  /// 计算字符串的 MD5 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return MD5 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.md5('Hello World');
  /// print(hash); // 输出: b10a8db164e0754105b7a99be72e3fe5
  /// ```
  static String md5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = crypto.md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// 文件 MD5 哈希
  ///
  /// 计算文件的 MD5 哈希值
  ///
  /// @param path 文件路径
  /// @return 文件的 MD5 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.pathMD5('/path/to/file.txt');
  /// print(hash); // 输出: 文件的 MD5 哈希值
  /// ```
  static String pathMD5(String path) {
    var file = File(path);
    var digest = crypto.md5.convert(file.readAsBytesSync());
    return hex.encode(digest.bytes);
  }

  /// SHA1 哈希
  ///
  /// 计算字符串的 SHA1 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA1 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.sha1('Hello World');
  /// print(hash); // 输出: 0a4d55a8d778e5022fab701977c5d840bbc486d0
  /// ```
  static String sha1(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha1.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// SHA256 哈希
  ///
  /// 计算字符串的 SHA256 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA256 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.sha256('Hello World');
  /// print(hash); // 输出: a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e
  /// ```
  static String sha256(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha256.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// SHA512 哈希
  ///
  /// 计算字符串的 SHA512 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA512 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.sha512('Hello World');
  /// print(hash); // 输出: 309ecc489c12d6eb4cc40f50c902f2b4d0ed77ee511a7c7a9bcd3ca86d4cd86f989dd35bc5ff499670da34255b45b0cfd830e81f605dcf7dc5542e93ae9cd76f
  /// ```
  static String sha512(String data) {
    var bytes = utf8.encode(data);
    var digest = crypto.sha512.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// HMAC-SHA256 哈希
  ///
  /// 计算字符串的 HMAC-SHA256 哈希值
  ///
  /// @param data 要哈希的数据
  /// @param key 密钥
  /// @return HMAC-SHA256 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WHash.hmacSha256('Hello World', 'secret');
  /// print(hash); // 输出: HMAC-SHA256 哈希值
  /// ```
  static String hmacSha256(String data, String key) {
    final hmac = crypto.Hmac(crypto.sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return hex.encode(digest.bytes);
  }

  /// 密码哈希（使用 HMAC-SHA256）
  ///
  /// 对密码进行哈希处理，使用盐值增强安全性
  ///
  /// @param password 密码
  /// @param salt 盐值，如果不提供则自动生成
  /// @return 密码哈希值，格式为 "sha256$盐值$哈希值"
  /// @example
  /// ```dart
  /// final hash = WHash.hashPassword('password123');
  /// print(hash); // 输出: sha256$盐值$哈希值
  /// ```
  static String hashPassword(String password, {String? salt}) {
    final saltStr = salt ?? _generateRandomSalt();
    final combined = '$password$saltStr';
    final hash = sha256(combined);
    return 'sha256\$$saltStr\$$hash';
  }

  /// 验证密码哈希
  ///
  /// 验证密码是否与哈希值匹配
  ///
  /// @param password 密码
  /// @param hash 密码哈希值
  /// @return 是否验证通过
  /// @example
  /// ```dart
  /// final hash = WHash.hashPassword('password123');
  /// final isMatch = WHash.verifyPassword('password123', hash);
  /// print(isMatch); // 输出: true
  /// ```
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

  /// 生成随机盐值
  ///
  /// 生成 16 字节的随机盐值，返回 Base64 编码的字符串
  ///
  /// @return 随机盐值（Base64 编码）
  static String _generateRandomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
