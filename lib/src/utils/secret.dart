import 'hash.dart';
import 'encrypt.dart';

/// 加密工具类，提供各种加密和哈希功能（聚合类）
///
/// 该类是一个聚合类，整合了 WHash 和 WEncrypt 的功能，提供统一的接口
class WSecret {
  /// MD5 哈希
  ///
  /// 计算字符串的 MD5 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return MD5 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WSecret.md5('Hello World');
  /// print(hash); // 输出: b10a8db164e0754105b7a99be72e3fe5
  /// ```
  static String md5(String data) {
    return WHash.md5(data);
  }

  /// 文件 MD5 哈希
  ///
  /// 计算文件的 MD5 哈希值
  ///
  /// @param path 文件路径
  /// @return 文件的 MD5 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WSecret.pathMD5('/path/to/file.txt');
  /// print(hash); // 输出: 文件的 MD5 哈希值
  /// ```
  static String pathMD5(String path) {
    return WHash.pathMD5(path);
  }

  /// Base64 编码
  ///
  /// 将字符串转换为 Base64 编码的字符串
  ///
  /// @param data 要编码的数据
  /// @return Base64 编码后的字符串
  /// @example
  /// ```dart
  /// final encoded = WSecret.base64Encode('Hello World');
  /// print(encoded); // 输出: SGVsbG8gV29ybGQ=
  /// ```
  static String base64Encode(String data) {
    return WEncrypt.base64Encode(data);
  }

  /// Base64 解码
  ///
  /// 将 Base64 编码的字符串解码为原始字符串
  ///
  /// @param data Base64 编码的字符串
  /// @return 解码后的数据
  /// @example
  /// ```dart
  /// final decoded = WSecret.base64Decode('SGVsbG8gV29ybGQ=');
  /// print(decoded); // 输出: Hello World
  /// ```
  static String base64Decode(String data) {
    return WEncrypt.base64Decode(data);
  }

  /// 生成安全的随机密钥
  ///
  /// 生成指定长度的安全随机密钥，返回 Base64 编码的字符串
  ///
  /// @param length 密钥长度，默认 32 字节
  /// @return 安全的随机密钥（Base64 编码）
  /// @example
  /// ```dart
  /// final key = WSecret.generateKey();
  /// print(key); // 输出: 随机生成的 32 字节密钥（Base64 编码）
  /// ```
  static String generateKey({int length = 32}) {
    return WEncrypt.generateKey(length: length);
  }

  /// 生成安全的随机 IV
  ///
  /// 生成指定长度的安全随机 IV（初始化向量），返回 Base64 编码的字符串
  ///
  /// @param length IV 长度，默认 16 字节
  /// @return 安全的随机 IV（Base64 编码）
  /// @example
  /// ```dart
  /// final iv = WSecret.generateIV();
  /// print(iv); // 输出: 随机生成的 16 字节 IV（Base64 编码）
  /// ```
  static String generateIV({int length = 16}) {
    return WEncrypt.generateIV(length: length);
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
  /// final key = WSecret.generateKey();
  /// final encrypted = WSecret.aesEncrypt('Hello World', keyStr: key);
  /// print(encrypted); // 输出: iv:密文
  /// ```
  static String aesEncrypt(
    String data, {
    required String keyStr,
    String? ivStr,
  }) {
    return WEncrypt.aesEncrypt(data, keyStr: keyStr, ivStr: ivStr);
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
  /// final key = WSecret.generateKey();
  /// final encrypted = WSecret.aesEncrypt('Hello World', keyStr: key);
  /// final decrypted = WSecret.aesDecrypt(encrypted, keyStr: key);
  /// print(decrypted); // 输出: Hello World
  /// ```
  static String aesDecrypt(
    String data, {
    required String keyStr,
  }) {
    return WEncrypt.aesDecrypt(data, keyStr: keyStr);
  }

  /// SHA1 哈希
  ///
  /// 计算字符串的 SHA1 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA1 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WSecret.sha1('Hello World');
  /// print(hash); // 输出: 0a4d55a8d778e5022fab701977c5d840bbc486d0
  /// ```
  static String sha1(String data) {
    return WHash.sha1(data);
  }

  /// SHA256 哈希
  ///
  /// 计算字符串的 SHA256 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA256 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WSecret.sha256('Hello World');
  /// print(hash); // 输出: a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e
  /// ```
  static String sha256(String data) {
    return WHash.sha256(data);
  }

  /// SHA512 哈希
  ///
  /// 计算字符串的 SHA512 哈希值
  ///
  /// @param data 要哈希的数据
  /// @return SHA512 哈希值（十六进制字符串）
  /// @example
  /// ```dart
  /// final hash = WSecret.sha512('Hello World');
  /// print(hash); // 输出: 309ecc489c12d6eb4cc40f50c902f2b4d0ed77ee511a7c7a9bcd3ca86d4cd86f989dd35bc5ff499670da34255b45b0cfd830e81f605dcf7dc5542e93ae9cd76f
  /// ```
  static String sha512(String data) {
    return WHash.sha512(data);
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
  /// final hash = WSecret.hmacSha256('Hello World', 'secret');
  /// print(hash); // 输出: HMAC-SHA256 哈希值
  /// ```
  static String hmacSha256(String data, String key) {
    return WHash.hmacSha256(data, key);
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
  /// final hash = WSecret.hashPassword('password123');
  /// print(hash); // 输出: sha256$盐值$哈希值
  /// ```
  static String hashPassword(String password, {String? salt}) {
    return WHash.hashPassword(password, salt: salt);
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
  /// final hash = WSecret.hashPassword('password123');
  /// final isMatch = WSecret.verifyPassword('password123', hash);
  /// print(isMatch); // 输出: true
  /// ```
  static bool verifyPassword(String password, String hash) {
    return WHash.verifyPassword(password, hash);
  }
}
