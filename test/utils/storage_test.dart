import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w_tools/src/utils/storage.dart';

void main() {
  group('WStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await WStorage.init();
      await WStorage.clear();
    });

    tearDown(() async {
      await WStorage.clear();
    });

    test('初始化测试', () {
      expect(WStorage.isInitialized, isTrue);
    });

    test('字符串存储与读取', () async {
      const key = 'test_string';
      const value = 'Hello World';

      await WStorage.setString(key, value);
      final result = WStorage.getString(key);

      expect(result, equals(value));
    });

    test('字符串默认值测试', () {
      const key = 'non_existent_key';
      const defaultValue = 'default';

      final result = WStorage.getString(key, defaultValue: defaultValue);

      expect(result, equals(defaultValue));
    });

    test('整数存储与读取', () async {
      const key = 'test_int';
      const value = 42;

      await WStorage.setInt(key, value);
      final result = WStorage.getInt(key);

      expect(result, equals(value));
    });

    test('布尔值存储与读取', () async {
      const key = 'test_bool';
      const value = true;

      await WStorage.setBool(key, value);
      final result = WStorage.getBool(key);

      expect(result, equals(value));
    });

    test('双精度浮点数存储与读取', () async {
      const key = 'test_double';
      const value = 3.14159;

      await WStorage.setDouble(key, value);
      final result = WStorage.getDouble(key);

      expect(result, equals(value));
    });

    test('字符串列表存储与读取', () async {
      const key = 'test_list';
      const value = ['a', 'b', 'c'];

      await WStorage.setStringList(key, value);
      final result = WStorage.getStringList(key);

      expect(result, equals(value));
    });

    test('对象存储与读取', () async {
      const key = 'test_object';
      final value = {'name': 'John', 'age': 25, 'isAdmin': true};

      await WStorage.setObject(key, value);
      final result = WStorage.getObject<Map<String, dynamic>>(key);

      expect(result, isNotNull);
      expect(result!['name'], equals('John'));
      expect(result['age'], equals(25));
      expect(result['isAdmin'], equals(true));
    });

    test('嵌套对象存储与读取', () async {
      const key = 'test_nested_object';
      final value = {
        'user': {'name': 'Alice', 'settings': {'darkMode': true}}
      };

      await WStorage.setObject(key, value);
      final result = WStorage.getObject<Map<String, dynamic>>(key);

      expect(result, isNotNull);
      expect(result!['user']['name'], equals('Alice'));
      expect(result['user']['settings']['darkMode'], equals(true));
    });

    test('对象默认值测试', () {
      const key = 'non_existent_object';
      final defaultValue = {'default': true};

      final result = WStorage.getObject<Map<String, dynamic>>(key, defaultValue: defaultValue);

      expect(result, equals(defaultValue));
    });

    test('删除测试', () async {
      const key = 'test_delete';
      const value = 'to be deleted';

      await WStorage.setString(key, value);
      expect(WStorage.getString(key), equals(value));

      await WStorage.remove(key);
      expect(WStorage.getString(key), isNull);
    });

    test('containsKey 测试', () async {
      const key = 'test_contains';

      expect(WStorage.containsKey(key), isFalse);

      await WStorage.setString(key, 'value');
      expect(WStorage.containsKey(key), isTrue);

      await WStorage.remove(key);
      expect(WStorage.containsKey(key), isFalse);
    });

    test('getKeys 测试', () async {
      await WStorage.clear();

      await WStorage.setString('key1', 'value1');
      await WStorage.setInt('key2', 2);

      final keys = WStorage.getKeys();
      expect(keys, isNotNull);
      expect(keys!.length, equals(2));
      expect(keys, contains('key1'));
      expect(keys, contains('key2'));
    });

    test('clear 测试', () async {
      await WStorage.setString('key1', 'value1');
      await WStorage.setInt('key2', 2);

      expect(WStorage.getString('key1'), isNotNull);
      expect(WStorage.getInt('key2'), isNotNull);

      await WStorage.clear();

      expect(WStorage.getString('key1'), isNull);
      expect(WStorage.getInt('key2'), isNull);
    });
  });
}
