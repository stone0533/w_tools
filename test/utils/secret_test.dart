import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/secret.dart';

void main() {
  group('WSecret Tests', () {
    // 测试 MD5 哈希
    test('md5 should return correct MD5 hash', () {
      final result = WSecret.md5('test');
      expect(result, '098f6bcd4621d373cade4e832627b4f6');
    });

    // 测试 SHA1 哈希
    test('sha1 should return correct SHA1 hash', () {
      final result = WSecret.sha1('test');
      expect(result, 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3');
    });

    // 测试 SHA256 哈希
    test('sha256 should return correct SHA256 hash', () {
      final result = WSecret.sha256('test');
      expect(result, '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08');
    });

    // 测试 SHA512 哈希
    test('sha512 should return correct SHA512 hash', () {
      final result = WSecret.sha512('test');
      expect(result, 'ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff');
    });

    // 测试 HMAC-SHA256 哈希
    test('hmacSha256 should return a valid HMAC-SHA256 hash', () {
      final result = WSecret.hmacSha256('test', 'key');
      // 验证结果长度是否正确（SHA256 哈希的十六进制表示长度为 64）
      expect(result.length, 64);
    });

    // 测试 Base64 编码和解码
    test('base64Encode and base64Decode should work correctly', () {
      const original = 'test data';
      final encoded = WSecret.base64Encode(original);
      final decoded = WSecret.base64Decode(encoded);
      expect(decoded, original);
    });

    // 测试 AES 加密和解密
    test('aesEncrypt and aesDecrypt should work correctly', () {
      const original = 'test data';
      final key = WSecret.generateKey();
      final encrypted = WSecret.aesEncrypt(original, keyStr: key);
      final decrypted = WSecret.aesDecrypt(encrypted, keyStr: key);
      expect(decrypted, original);
    });

    // 测试密码哈希和验证
    test('Password hash and verify should work correctly', () {
      const password = 'test_password';
      final hash = WSecret.hashPassword(password);
      final isVerified = WSecret.verifyPassword(password, hash);
      expect(isVerified, true);

      // 测试错误密码
      final isVerifiedWrong = WSecret.verifyPassword('wrong_password', hash);
      expect(isVerifiedWrong, false);
    });

    // 测试安全密钥生成
    test('generateKey should generate a key of correct length', () {
      const length = 32;
      final key = WSecret.generateKey(length: length);
      // Base64 编码的 32 字节数据长度应该是 44 个字符（包括填充）
      expect(key.length, 44);
    });

    // 测试安全 IV 生成
    test('generateIV should generate an IV of correct length', () {
      const length = 16;
      final iv = WSecret.generateIV(length: length);
      // Base64 编码的 16 字节数据长度应该是 24 个字符（包括填充）
      expect(iv.length, 24);
    });
  });
}
