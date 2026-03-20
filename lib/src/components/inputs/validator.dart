import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// 自定义验证器类，继承自 BaseValidator
class _WCustomValidator<T> extends BaseValidator<T> {
  /// 自定义验证函数
  final String? Function(T?) validator;

  /// 构造函数
  ///
  /// @param validator 自定义验证函数，返回错误信息或 null
  const _WCustomValidator({required this.validator}) : super(checkNullOrEmpty: false);

  @override
  /// 验证值
  ///
  /// @param value 待验证的值
  /// @return 错误信息或 null
  String? validateValue(T value) => validator.call(value);
}

/// FormBuilderValidators 的扩展，提供自定义验证器
///
/// 用于创建自定义验证规则，通过传入一个验证函数来实现
/// 验证函数返回错误信息字符串或 null（表示验证通过）
extension WCustomValidator on FormBuilderValidators {
  /// 创建自定义验证器
  ///
  /// @param validator 自定义验证函数，返回错误信息或 null
  /// @return 表单字段验证器
  static FormFieldValidator<T> custom<T>({
    required String? Function(T?) validator,
  }) => _WCustomValidator<T>(validator: validator).validate;
}
