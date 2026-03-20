import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/toast.dart';

void main() {
  group('WToast', () {
    test('showSuccess should not throw when message is not empty', () {
      expect(() => WToast.showSuccess('Test success'), returnsNormally);
    });

    test('showSuccess should throw when message is empty', () {
      expect(() => WToast.showSuccess(''), throwsAssertionError);
    });

    test('showError should not throw when message is not empty', () {
      expect(() => WToast.showError('Test error'), returnsNormally);
    });

    test('showError should throw when message is empty', () {
      expect(() => WToast.showError(''), throwsAssertionError);
    });

    test('showWarning should not throw when message is not empty', () {
      expect(() => WToast.showWarning('Test warning'), returnsNormally);
    });

    test('showWarning should throw when message is empty', () {
      expect(() => WToast.showWarning(''), throwsAssertionError);
    });

    test('showLoading should return a cancel function', () {
      final cancelFunc = WToast.showLoading();
      expect(cancelFunc, isNotNull);
      expect(cancelFunc, isA<Function>());
      WToast.hideLoading();
    });

    test('hideLoading should not throw when no loading is shown', () {
      expect(() => WToast.hideLoading(), returnsNormally);
    });
  });

  group('WToastConfig', () {
    test('instance should return the same instance', () {
      final instance1 = WToastConfig.instance;
      final instance2 = WToastConfig.instance;
      expect(instance1, same(instance2));
    });

    test('reset should create a new instance', () {
      final instance1 = WToastConfig.instance;
      WToastConfig.reset();
      final instance2 = WToastConfig.instance;
      expect(instance1, isNot(same(instance2)));
    });



    test('showSuccess should not throw when message is not empty', () {
      expect(() => WToastConfig.instance.showSuccess('Test success'), returnsNormally);
    });

    test('showError should not throw when message is not empty', () {
      expect(() => WToastConfig.instance.showError('Test error'), returnsNormally);
    });

    test('showWarning should not throw when message is not empty', () {
      expect(() => WToastConfig.instance.showWarning('Test warning'), returnsNormally);
    });

    test('showLoading should return a cancel function', () {
      final cancelFunc = WToastConfig.instance.showLoading();
      expect(cancelFunc, isNotNull);
      expect(cancelFunc, isA<Function>());
      WToastConfig.instance.hideLoading();
    });

    test('hideLoading should not throw when no loading is shown', () {
      expect(() => WToastConfig.instance.hideLoading(), returnsNormally);
    });
  });

  group('WToastTheme', () {
    test('light theme should have default values', () {
      expect(WToastTheme.light.successColor, equals(Colors.green));
      expect(WToastTheme.light.errorColor, equals(Colors.red));
      expect(WToastTheme.light.warningColor, equals(Colors.orange));
      expect(WToastTheme.light.messageColor, equals(Colors.black38));
    });

    test('dark theme should have different values', () {
      expect(WToastTheme.dark.successColor, equals(Colors.greenAccent));
      expect(WToastTheme.dark.errorColor, equals(Colors.redAccent));
      expect(WToastTheme.dark.warningColor, equals(Colors.orangeAccent));
      expect(WToastTheme.dark.messageColor, equals(Colors.black54));
    });
  });
}
