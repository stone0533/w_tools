import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// 自定义校验器，继承自 [BaseValidator]
///
/// 与父类默认行为不同：无论值是否为 null/空，都会把原始值交给自定义函数判断，
/// 因此自定义函数可以自行实现「必填」等针对空值的规则。
class _WFormCustomValidator<T> extends BaseValidator<T> {
  /// 自定义校验函数
  final String? Function(T?) validator;

  /// 创建自定义校验器
  ///
  /// 传入 `checkNullOrEmpty: false` 仅表达「不希望父类对空值做短路」的意图；
  /// 真正绕开短路的是下方的 [validate] 覆写。
  const _WFormCustomValidator({required this.validator}) : super(checkNullOrEmpty: false);

  /// 校验值
  ///
  /// 覆写以绕开 [BaseValidator] 对空值的「直接放行」：空值同样交给 [validator] 判断。
  @override
  String? validate(T? value) => validator.call(value);

  /// [BaseValidator] 的抽象方法
  ///
  /// 本类经 [validate] 直接分发，此实现仅为满足抽象契约、行为与 [validate] 保持一致
  @override
  String? validateValue(T value) => validator.call(value);
}

/// 自定义校验器命名空间（面向 [FormBuilderValidators]）
///
/// 用于创建自定义校验规则：传入一个校验函数，函数返回错误信息字符串表示校验失败，
/// 返回 null 表示通过。
///
/// 调用方式为 `WFormCustomValidator.custom(...)`。
abstract final class WFormCustomValidator {
  /// 创建自定义校验器：校验函数返回错误信息表示失败，返回 null 表示通过
  static FormFieldValidator<T> custom<T>({
    required String? Function(T?) validator,
  }) => _WFormCustomValidator<T>(validator: validator).validate;
}
