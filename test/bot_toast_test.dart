import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/toast.dart';

void main() {
  group('WToast', () {
    test('showCustomDialog should not throw', () {
      expect(
        () => WToast.showCustomDialog(
          toastBuilder: (_) => Container(),
        ),
        returnsNormally,
      );
    });

    test('showLoading should return a cancel function', () {
      final config = WToastConfig();
      config.loadingBuilder = (message, cancelFunc, dismissible) => Container();
      final cancelFunc = config.showLoading();
      expect(cancelFunc, isNotNull);
      expect(cancelFunc, isA<Function>());
      config.hideLoading();
    });

    test('WToastConfig hideLoading should not throw when no loading is shown', () {
      final config = WToastConfig();
      expect(() => config.hideLoading(), returnsNormally);
    });
  });

  group('WToastConfig', () {
    test('should create new instances', () {
      final instance1 = WToastConfig();
      final instance2 = WToastConfig();
      expect(instance1, isNot(same(instance2)));
    });

    test('showSuccess should not throw when message is not empty', () {
      final config = WToastConfig();
      config.successBuilder = (message, cancelFunc) => Container();
      expect(() => config.showSuccess('Test success'), returnsNormally);
    });

    test('showError should not throw when message is not empty', () {
      final config = WToastConfig();
      config.errorBuilder = (message, cancelFunc) => Container();
      expect(() => config.showError('Test error'), returnsNormally);
    });

    test('showWarning should not throw when message is not empty', () {
      final config = WToastConfig();
      config.warningBuilder = (message, cancelFunc) => Container();
      expect(() => config.showWarning('Test warning'), returnsNormally);
    });

    test('showLoading should return a cancel function', () {
      final config = WToastConfig();
      config.loadingBuilder = (message, cancelFunc, dismissible) => Container();
      final cancelFunc = config.showLoading();
      expect(cancelFunc, isNotNull);
      expect(cancelFunc, isA<Function>());
      config.hideLoading();
    });

    test('hideLoading should not throw when no loading is shown', () {
      final config = WToastConfig();
      expect(() => config.hideLoading(), returnsNormally);
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
