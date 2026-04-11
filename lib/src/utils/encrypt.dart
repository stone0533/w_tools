import 'dart:convert' as convert;
import 'package:encrypt/encrypt.dart';
import 'dart:math';

/// 加密工具类，提供各种加密功能
///
/// 该类封装了常用的加密功能，包括 Base64 编解码和 AES 加密解密
class WEncrypt {
  /// Base64 编码
  ///
  /// 将字符串转换为 Base64 编码的字符串
  ///
  /// @param data 要编码的数据
  /// @return Base64 编码后的字符串
  /// @example
  /// ```dart
  /// final encoded = WEncrypt.base64Encode('Hello World');
  /// print(encoded); // 输出: SGVsbG8gV29ybGQ=
  /// ```
  static String base64Encode(String data) {
    var content = convert.utf8.encode(data);
    var digest = convert.base64Encode(content);
    return digest;
  }

  /// Base64 解码
  ///
  /// 将 Base64 编码的字符串解码为原始字符串
  ///
  /// @param data Base64 编码的字符串
  /// @return 解码后的数据
  /// @example
  /// ```dart
  /// final decoded = WEncrypt.base64Decode('SGVsbG8gV29ybGQ=');
  /// print(decoded); // 输出: Hello World
  /// ```
  static String base64Decode(String data) {
    return String.fromCharCodes(convert.base64Decode(data));
  }

  /// 生成安全的随机密钥
  ///
  /// 生成指定长度的安全随机密钥，返回 Base64 编码的字符串
  ///
  /// @param length 密钥长度，默认 32 字节
  /// @return 安全的随机密钥（Base64 编码）
  /// @example
  /// ```dart
  /// final key = WEncrypt.generateKey();
  /// print(key); // 输出: 随机生成的 32 字节密钥（Base64 编码）
  /// ```
  static String generateKey({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return convert.base64Encode(bytes);
  }

  /// 生成安全的随机 IV
  ///
  /// 生成指定长度的安全随机 IV（初始化向量），返回 Base64 编码的字符串
  ///
  /// @param length IV 长度，默认 16 字节
  /// @return 安全的随机 IV（Base64 编码）
  /// @example
  /// ```dart
  /// final iv = WEncrypt.generateIV();
  /// print(iv); // 输出: 随机生成的 16 字节 IV（Base64 编码）
  /// ```
  static String generateIV({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return convert.base64Encode(bytes);
  }

  /// AES 加密（使用 CBC 模式）
  ///
  /// 使用 AES-CBC 模式加密数据，返回包含 IV 和密文的字符串
  ///
  /// @param data 要加密的数据
  /// @param keyStr 密钥（Base64 编码）
  /// @param ivStr IV（Base64 编码），如果不提供则自动生成
  /// @return 加密后的结果，格式为 "iv:密文"
  /// @example
  /// ```dart
  /// final key = WEncrypt.generateKey();
  /// final encrypted = WEncrypt.aesEncrypt('Hello World', keyStr: key);
  /// print(encrypted); // 输出: iv:密文
  /// ```
  static String aesEncrypt(
    String data, {
    required String keyStr,
    String? ivStr,
  }) {
    final plainText = data;
    final key = Key.fromBase64(keyStr);
    final iv = ivStr != null ? IV.fromBase64(ivStr) : IV.fromLength(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // 返回 iv 和密文的组合，使用 : 分隔
    return '${iv.base64}:${encrypted.base64}';
  }

  /// AES 解密（使用 CBC 模式）
  ///
  /// 使用 AES-CBC 模式解密数据，从 "iv:密文" 格式的字符串中提取 IV 和密文
  ///
  /// @param data 加密的数据，格式为 "iv:密文"
  /// @param keyStr 密钥（Base64 编码）
  /// @return 解密后的数据
  /// @throws Exception 如果加密数据格式不正确
  /// @example
  /// ```dart
  /// final key = WEncrypt.generateKey();
  /// final encrypted = WEncrypt.aesEncrypt('Hello World', keyStr: key);
  /// final decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);
  /// print(decrypted); // 输出: Hello World
  /// ```
  static String aesDecrypt(
    String data, {
    required String keyStr,
  }) {
    // 解析 iv 和密文
    final parts = data.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    final key = Key.fromBase64(keyStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt(
      encrypted,
      iv: iv,
    );
    return decrypted;
  }
}
