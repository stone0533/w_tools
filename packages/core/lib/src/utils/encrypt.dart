import 'dart:convert' as convert;
import 'package:encrypt/encrypt.dart';
import 'dart:math';

/// 加密工具类
///
/// 提供 Base64 编解码、安全随机密钥 / IV 生成与 AES-CBC 加解密。
class WEncrypt {
  // 纯静态工具类，禁止实例化
  WEncrypt._();

  /// 将字符串按 UTF-8 转为 Base64
  static String base64Encode(String data) {
    var content = convert.utf8.encode(data);
    var digest = convert.base64Encode(content);
    return digest;
  }

  /// 将 Base64 解码为 UTF-8 字符串
  ///
  /// 输入不是合法 Base64 / UTF-8 时会抛出 [FormatException]。
  static String base64Decode(String data) {
    return convert.utf8.decode(convert.base64Decode(data));
  }

  /// 生成安全随机密钥（Base64 编码）
  ///
  /// [length] 为字节数，默认 32（AES-256）；AES 密钥长度需为 16 / 24 / 32。
  static String generateKey({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return convert.base64Encode(bytes);
  }

  /// 生成安全随机 IV（Base64 编码）
  ///
  /// [length] 为字节数，默认 16；AES-CBC 的 IV 固定为 16 字节。
  static String generateIv({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return convert.base64Encode(bytes);
  }

  /// AES-CBC 加密
  ///
  /// 返回 `iv:密文`（两部分均为 Base64）；未传 [ivStr] 时生成 16 字节
  /// 安全随机 IV，保证相同明文每次加密结果不同。
  static String aesEncrypt(
    String data, {
    required String keyStr,
    String? ivStr,
  }) {
    final plainText = data;
    final key = Key.fromBase64(keyStr);
    // 未指定 IV 时使用安全随机值，保证相同明文每次加密结果不同。
    // 不使用 IV.fromLength：该方法在不同 encrypt 版本中语义不一致
    // （5.0.1 为全零，5.0.3 起才改为安全随机）。
    final iv = ivStr != null ? IV.fromBase64(ivStr) : IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // 输出 `iv:密文`（两部分均为 Base64）
    return '${iv.base64}:${encrypted.base64}';
  }

  /// AES-CBC 解密
  ///
  /// [data] 必须是 `iv:密文` 格式，否则抛出 [Exception]。
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
