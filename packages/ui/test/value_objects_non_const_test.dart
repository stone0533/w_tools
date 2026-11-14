// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget? _placeholder(BuildContext context, String data) => null;

void _expectValueEquality<T>(T a, T b, {String? reason}) {
  expect(identical(a, b), isFalse, reason: '测试必须使用非 const 实例');
  expect(a, b, reason: reason);
  expect(a.hashCode, b.hashCode, reason: reason);
}

void main() {
  test('WAppBarStyle 非 const 值相等', () {
    final a = WAppBarStyle(height: 56, boxShadow: [BoxShadow(color: Colors.black12)]);
    final b = WAppBarStyle(height: 56, boxShadow: [BoxShadow(color: Colors.black12)]);
    _expectValueEquality(a, b);
  });

  test('WButtonSize 非 const 值相等', () {
    _expectValueEquality(
      WButtonSize(minWidth: 10, minHeight: 20, padding: EdgeInsets.zero),
      WButtonSize(minWidth: 10, minHeight: 20, padding: EdgeInsets.zero),
    );
  });

  test('WStepStyle / WStepColors 非 const 值相等', () {
    _expectValueEquality(
      WStepStyle(itemSize: 30, labelSpacing: 6),
      WStepStyle(itemSize: 30, labelSpacing: 6),
    );
    _expectValueEquality(
      WStepColors(completed: Colors.green, current: Colors.blue, upcoming: Colors.grey),
      WStepColors(completed: Colors.green, current: Colors.blue, upcoming: Colors.grey),
    );
  });

  test('WBadgeStyle / WBadgePosition 非 const 值相等', () {
    _expectValueEquality(
      WBadgeStyle(backgroundColor: Colors.red, padding: EdgeInsets.zero),
      WBadgeStyle(backgroundColor: Colors.red, padding: EdgeInsets.zero),
    );
    _expectValueEquality(
      WBadgePosition.topEnd(top: 1, end: 2),
      WBadgePosition.topEnd(top: 1, end: 2),
    );
  });

  test('WImageStyle / WImageLoadOptions 非 const 值相等', () {
    _expectValueEquality(
      WImageStyle(width: 10, height: 20, fit: BoxFit.contain),
      WImageStyle(width: 10, height: 20, fit: BoxFit.contain),
    );
    _expectValueEquality(
      WImageLoadOptions(memCacheWidth: 100, retryCount: 2),
      WImageLoadOptions(memCacheWidth: 100, retryCount: 2),
    );
  });

  test('WImageSlots 非 const 值相等（同一 builder）', () {
    _expectValueEquality(
      WImageSlots(placeholderBuilder: _placeholder),
      WImageSlots(placeholderBuilder: _placeholder),
    );
  });

  test('WImage 错误 / 进度 / 快照非 const 值相等', () {
    _expectValueEquality(
      WImageProgress(downloadedBytes: 1, totalBytes: 2),
      WImageProgress(downloadedBytes: 1, totalBytes: 2),
    );
    _expectValueEquality(
      WImageError('url', WImageErrorKind.network),
      WImageError('url', WImageErrorKind.network),
    );
  });

  test('WImageSource 家族非 const 值相等', () {
    _expectValueEquality(
      WImageSource.network('https://example.com/a.png'),
      WImageSource.network('https://example.com/a.png'),
    );
    _expectValueEquality(
      WImageSource.asset('logo.png'),
      WImageSource.asset('logo.png'),
    );
    _expectValueEquality(
      WImageSource.file('/tmp/a.png'),
      WImageSource.file('/tmp/a.png'),
    );
    _expectValueEquality(
      WImageSource.base64('AAAA'),
      WImageSource.base64('AAAA'),
    );
  });

  test('WScreenData 非 const 值相等', () {
    _expectValueEquality(
      WScreenData(size: const Size(390, 844), padding: EdgeInsets.zero),
      WScreenData(size: const Size(390, 844), padding: EdgeInsets.zero),
    );
  });

  test('WTextStyles 非 const 值相等', () {
    final base = ThemeData.light().textTheme;
    _expectValueEquality(WTextStyles.fromTextTheme(base), WTextStyles.fromTextTheme(base));
  });
}
