import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/src/utils/hash.dart';
import 'package:w_tools_core/src/utils/encrypt.dart';

void main() {
  group('WHash', () {
    test('md5 已知向量', () {
      expect(WHash.md5(''), 'd41d8cd98f00b204e9800998ecf8427e');
      expect(WHash.md5('a'), '0cc175b9c0f1b6a831c399e269772661');
      expect(WHash.md5('Hello World'), 'b10a8db164e0754105b7a99be72e3fe5');
    });

    test('sha256 已知向量', () {
      expect(
        WHash.sha256('Hello World'),
        'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
      );
    });

    test('sha512 已知向量', () {
      final result = WHash.sha512('Hello World');
      expect(result, hasLength(128));
      // 'Hello World' 的 SHA512 实际值前缀
      expect(result, startsWith('2c74fd17'));
    });

    test('bytesMd5 字节哈希', () {
      final bytes = File('/tmp/test_hash_${DateTime.now().millisecondsSinceEpoch}.txt');
      bytes.writeAsStringSync('test content');
      final hash = WHash.bytesMd5(bytes.readAsBytesSync());
      expect(hash, WHash.md5('test content'));
      bytes.deleteSync();
    });

    test('bytesMd5 空字节', () {
      expect(WHash.bytesMd5([]), WHash.md5(''));
    });

    test('hmacSha256 相同输入相同输出', () {
      final h1 = WHash.hmacSha256('data', 'key');
      final h2 = WHash.hmacSha256('data', 'key');
      expect(h1, h2);
      expect(h1, hasLength(64));
    });

    test('hmacSha256 不同 key 不同输出', () {
      final h1 = WHash.hmacSha256('data', 'key1');
      final h2 = WHash.hmacSha256('data', 'key2');
      expect(h1, isNot(h2));
    });

    test('hashPassword 自动生成 salt', () {
      final h1 = WHash.hashPassword('password');
      final h2 = WHash.hashPassword('password');
      // salt 是随机的，所以不同调用产生不同 hash
      expect(h1, isNot(h2));
      expect(h1.split('\$').length, 3);
    });

    test('hashPassword 指定 salt', () {
      final h1 = WHash.hashPassword('password', salt: 'fixed_salt');
      final h2 = WHash.hashPassword('password', salt: 'fixed_salt');
      expect(h1, h2); // 相同 salt 产生相同 hash
    });

    test('verifyPassword - 正确密码', () {
      final hash = WHash.hashPassword('mypassword', salt: 'salt123');
      expect(WHash.verifyPassword('mypassword', hash), isTrue);
    });

    test('verifyPassword - 错误密码', () {
      final hash = WHash.hashPassword('mypassword');
      expect(WHash.verifyPassword('wrongpassword', hash), isFalse);
    });

    test('verifyPassword - 格式错误', () {
      expect(WHash.verifyPassword('pwd', 'invalid_format'), isFalse);
      expect(WHash.verifyPassword('pwd', 'sha256\$only_two'), isFalse);
    });
  });

  group('WEncrypt', () {
    test('base64 编解码对称', () {
      const data = 'Hello World';
      final encoded = WEncrypt.base64Encode(data);
      expect(WEncrypt.base64Decode(encoded), data);
    });

    test('base64 编解码对称 — 中文与 emoji 往返', () {
      const data = '你好，世界 🌍🚀 Hello';
      final encoded = WEncrypt.base64Encode(data);
      // 编码端为 UTF-8
      expect(encoded, base64Encode(utf8.encode(data)));
      // 解码端须按 UTF-8 还原（回归：曾用 String.fromCharCodes 导致多字节乱码）
      expect(WEncrypt.base64Decode(encoded), data);
    });

    test('generateKey 默认 32 字节 → 44 Base64', () {
      final key = WEncrypt.generateKey();
      // Base64 32 bytes = ceil(32/3)*4 = 44
      expect(key.length, 44);
    });

    test('generateKey 可指定长度', () {
      final key = WEncrypt.generateKey(length: 16);
      expect(key.length, 24); // ceil(16/3)*4 = 24
    });

    test('generateIv 默认 16 字节 → 24 Base64', () {
      final iv = WEncrypt.generateIv();
      expect(iv.length, 24);
    });

    test('aesEncrypt/aesDecrypt 对称', () {
      final key = WEncrypt.generateKey();
      const plain = '这是一段中文明文 Hello 123';
      final encrypted = WEncrypt.aesEncrypt(plain, keyStr: key);
      final decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);
      expect(decrypted, plain);
    });

    test('aesEncrypt 指定自定义 iv', () {
      final key = WEncrypt.generateKey();
      final iv = WEncrypt.generateIv();
      const plain = 'test with custom iv';
      final encrypted = WEncrypt.aesEncrypt(plain, keyStr: key, ivStr: iv);
      final decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);
      expect(decrypted, plain);
    });

    test('aesDecrypt 错误格式抛出', () {
      final key = WEncrypt.generateKey();
      expect(() => WEncrypt.aesDecrypt('invalid', keyStr: key), throwsException);
      expect(() => WEncrypt.aesDecrypt('only_one_part', keyStr: key), throwsException);
    });

    test('相同明文不同加密（默认自动生成 iv）', () {
      final key = WEncrypt.generateKey();
      final e1 = WEncrypt.aesEncrypt('same plain', keyStr: key);
      final e2 = WEncrypt.aesEncrypt('same plain', keyStr: key);
      expect(e1, isNot(e2)); // 每次 iv 不同，密文不同
    });

    test('默认 IV 为 16 字节安全随机值且非全零', () {
      final key = WEncrypt.generateKey();
      List<int> extractIv(String encrypted) => base64Decode(encrypted.split(':').first);

      final iv1 = extractIv(WEncrypt.aesEncrypt('iv check', keyStr: key));
      final iv2 = extractIv(WEncrypt.aesEncrypt('iv check', keyStr: key));

      expect(iv1, hasLength(16));
      expect(iv1.every((byte) => byte == 0), isFalse);
      expect(iv1, isNot(equals(iv2)));
    });
  });
}
