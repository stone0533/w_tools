import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  test('各 Config Builder 可生成同类型副本', () {
    final text = WFormTextFieldConfig.builder()..height = 52;
    final textConfig = text.buildConfig();
    expect(textConfig, isA<WFormTextFieldConfig>());
    expect(textConfig.height, 52);
    expect(identical(text, textConfig), isFalse);

    final dropdown = WFormDropdownConfig.builder()..height = 48;
    final dropdownConfig = dropdown.buildConfig();
    expect(dropdownConfig, isA<WFormDropdownConfig>());
    expect(dropdownConfig.height, 48);

    final date = WFormDatePickerConfig.builder()..height = 50;
    final dateConfig = date.buildConfig();
    expect(dateConfig, isA<WFormDatePickerConfig>());
    expect(dateConfig.height, 50);

    final checkbox = WFormCheckboxConfig.builder()..height = 44;
    final checkboxConfig = checkbox.buildConfig();
    expect(checkboxConfig, isA<WFormCheckboxConfig>());
    expect(checkboxConfig.height, 44);

    final radio = WFormRadioGroupConfig.builder()..height = 42;
    final radioConfig = radio.buildConfig();
    expect(radioConfig, isA<WFormRadioGroupConfig>());
    expect(radioConfig.height, 42);

    final multi = WFormMultiDropdownConfig.builder()..height = 46;
    final multiConfig = multi.buildConfig();
    expect(multiConfig, isA<WFormMultiDropdownConfig>());
    expect(multiConfig.height, 46);

    final button = WFormFieldButtonConfig.builder()
      ..hintWidget = const Text('选择')
      ..height = 40;
    final buttonConfig = button.buildConfig();
    expect(buttonConfig, isA<WFormFieldButtonConfig>());
    expect(buttonConfig.height, 40);

    final validator = WFormValidatorConfig.builder()
      ..showBorderError = true
      ..continueOnError = true;
    final validatorConfig = validator.buildConfig();
    expect(validatorConfig, isA<WFormValidatorConfig>());

    final border = WFormBorderConfig.builder()
      ..defaultDecoration = const WFormBorderDecoration(color: Colors.white);
    final borderConfig = border.buildConfig();
    expect(borderConfig, isA<WFormBorderConfig>());
  });
}
