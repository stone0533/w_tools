import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:io';
import 'dart:math';

/// 加密工具类，提供各种加密和哈希功能
class WSecret {
  /// MD5 哈希
  ///
  /// @param data 要哈希的数据
  /// @return MD5 哈希值
  static String hashMD5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// 文件 MD5 哈希
  ///
  /// @param path 文件路径
  /// @return 文件的 MD5 哈希值
  static String hashPathMD5(String path) {
    var file = File(path);
    var digest = md5.convert(file.readAsBytesSync());
    return hex.encode(digest.bytes);
  }

  /// Base64 编码
  ///
  /// @param data 要编码的数据
  /// @return Base64 编码后的字符串
  static String encodeBase64(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  /// Base64 解码
  ///
  /// @param data Base64 编码的字符串
  /// @return 解码后的数据
  static String decodeBase64(String data) {
    return String.fromCharCodes(base64Decode(data));
  }

  /// 生成安全的随机密钥
  ///
  /// @param length 密钥长度，默认 32 字节
  /// @return 安全的随机密钥（Base64 编码）
  static String generateSecureKey({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// 生成安全的随机 IV
  ///
  /// @param length IV 长度，默认 16 字节
  /// @return 安全的随机 IV（Base64 编码）
  static String generateSecureIV({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// AES 加密（使用 CBC 模式）
  ///
  /// @param data 要加密的数据
  /// @param keyStr 密钥（Base64 编码）
  /// @param ivStr IV（Base64 编码），如果不提供则自动生成
  /// @return 加密后的结果，格式为 "iv:密文"
  static String encryptAES(
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
  /// @param data 加密的数据，格式为 "iv:密文"
  /// @param keyStr 密钥（Base64 编码）
  /// @return 解密后的数据
  static String decryptAES(
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

  /// SHA1 哈希
  ///
  /// @param data 要哈希的数据
  /// @return SHA1 哈希值
  static String encryptSha1(String data) {
    var bytes = utf8.encode(data);
    var digest = sha1.convert(bytes).bytes;
    return hex.encode(digest);
  }

  /// SHA256 哈希
  ///
  /// @param data 要哈希的数据
  /// @return SHA256 哈希值
  static String encryptSha256(String data) {
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes).bytes;
    return hex.encode(digest);
  }

  /// SHA512 哈希
  ///
  /// @param data 要哈希的数据
  /// @return SHA512 哈希值
  static String encryptSha512(String data) {
    var bytes = utf8.encode(data);
    var digest = sha512.convert(bytes).bytes;
    return hex.encode(digest);
  }

  /// HMAC-SHA256 哈希
  ///
  /// @param data 要哈希的数据
  /// @param key 密钥
  /// @return HMAC-SHA256 哈希值
  static String hmacSha256(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return hex.encode(digest.bytes);
  }

  /// 密码哈希（使用 PBKDF2）
  ///
  /// @param password 密码
  /// @param salt 盐值，如果不提供则自动生成
  /// @return 密码哈希值
  static String hashPassword(String password, {String? salt}) {
    final saltBytes = salt != null
        ? utf8.encode(salt)
        : List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltStr = salt ?? base64Encode(saltBytes);

    // 使用 PBKDF2 算法
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256, utf8.encode('')),
      iterations: 10000,
      bits: 256,
    );

    final key = pbkdf2.convert(
      utf8.encode(password),
      salt: saltBytes,
    );

    return 'pbkdf210000$saltStr${hex.encode(key)}';
  }

  /// 验证密码哈希
  ///
  /// @param password 密码
  /// @param hash 密码哈希值
  /// @return 是否验证通过
  static bool verifyPassword(String password, String hash) {
    final parts = hash.split('\$');
    if (parts.length != 4) {
      return false;
    }

    final salt = parts[2];
    final expectedHash = parts[3];

    final computedHash = hashPassword(password, salt: salt);
    final computedHashParts = computedHash.split('\$');

    return computedHashParts[3] == expectedHash;
  }
}

/// PBKDF2 算法实现
class Pbkdf2 {
  /// 消息认证码算法
  final Hmac macAlgorithm;

  /// 迭代次数
  final int iterations;

  /// 密钥位数
  final int bits;

  /// 构造函数
  ///
  /// @param macAlgorithm 消息认证码算法
  /// @param iterations 迭代次数
  /// @param bits 密钥位数
  Pbkdf2({
    required this.macAlgorithm,
    required this.iterations,
    required this.bits,
  });

  /// 转换密码为密钥
  ///
  /// @param password 密码
  /// @param salt 盐值
  /// @return 生成的密钥
  List<int> convert(List<int> password, {required List<int> salt}) {
    const blockSize = 32; // SHA-256 block size
    final keyLength = (bits + 7) ~/ 8;
    final blocks = (keyLength + blockSize - 1) ~/ blockSize;

    final result = <int>[];

    for (var i = 1; i <= blocks; i++) {
      var block = _computeBlock(password, salt, i);
      result.addAll(block);
    }

    return result.take(keyLength).toList();
  }

  /// 计算单个块
  ///
  /// @param password 密码
  /// @param salt 盐值
  /// @param blockIndex 块索引
  /// @return 计算的块
  List<int> _computeBlock(List<int> password, List<int> salt, int blockIndex) {
    final indexBytes = _intToBytes(blockIndex);
    var block = macAlgorithm.convert([...salt, ...indexBytes]).bytes;
    var previous = block;

    for (var i = 1; i < iterations; i++) {
      previous = macAlgorithm.convert([...password, ...previous]).bytes;
      block = _xorLists(block, previous);
    }

    return block;
  }

  /// 将整数转换为字节
  ///
  /// @param value 整数
  /// @return 字节列表
  List<int> _intToBytes(int value) {
    final bytes = <int>[];
    for (var i = 3; i >= 0; i--) {
      bytes.add((value >> (i * 8)) & 0xff);
    }
    return bytes;
  }

  /// 异或两个列表
  ///
  /// @param a 第一个列表
  /// @param b 第二个列表
  /// @return 异或结果
  List<int> _xorLists(List<int> a, List<int> b) {
    final result = <int>[];
    for (var i = 0; i < a.length; i++) {
      result.add(a[i] ^ b[i]);
    }
    return result;
  }
}
