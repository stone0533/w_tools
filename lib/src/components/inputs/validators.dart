import 'package:flutter/cupertino.dart';
import 'data.dart';

/// 表单验证器类，用于管理和执行表单验证
class WFormValidators {
  /// 表单数据对象
  WFormData formData;

  /// 验证项列表
  List<WFormValidatorsItem> validationItems;

  /// 验证器配置
  WFormValidatorsConfig? config;

  /// 构造函数
  ///
  /// @param formData 表单数据对象
  /// @param validationItems 验证项列表
  /// @param config 验证器配置
  WFormValidators({required this.formData, required this.validationItems, this.config});

  /// 添加验证项
  ///
  /// @param item 验证项
  void add(WFormValidatorsItem item) {
    validationItems.add(item);
  }

  /// 执行验证
  ///
  /// @return 验证是否通过
  bool validate() {
    // 关闭键盘
    formData.closeKeyboard();
    var formKey = formData.formKey;
    formKey.currentState?.save();
    config ??= WFormValidatorsConfig();

    // 遍历验证项
    for (var item in validationItems) {
      // 检查是否需要跳过当前校验
      bool shouldSkip = config?._shouldSkipValidation?.call(item.fieldName, formKey.currentState?.value) ?? false;
      if (shouldSkip) {
        // 跳过当前校验，继续下一项
        continue;
      }
      
      String? errorText = item.validatorBuilder().call(formKey.currentState?.value[item.fieldName]);
      bool isValid = errorText == null;
      
      // 调用每一项校验的结果回调
      config?._itemValidationCallback?.call(item.fieldName, isValid, errorText);
      
      if (errorText != null) {
        if (config?._showBorderError == true) {
          formData.setError(
            item.fieldName,
            errorList: {
              item.fieldName: [errorText],
            },
            callback: () {
              if (item.autoFocus == true) {
                formKey.currentState?.fields[item.fieldName]?.focus();
              }
            },
          );
        }
        config?._customErrorHandler?.call(item.fieldName, errorText);
        return false;
      }
    }
    return true;
  }
}

/// 表单验证项类，定义单个字段的验证规则
class WFormValidatorsItem {
  /// 字段名称
  String fieldName;

  /// 验证函数生成器
  FormFieldValidator<dynamic> Function() validatorBuilder;

  /// 是否自动聚焦到错误字段
  bool autoFocus;

  /// 构造函数
  ///
  /// @param fieldName 字段名称
  /// @param validatorBuilder 验证函数生成器
  /// @param autoFocus 是否自动聚焦到错误字段
  WFormValidatorsItem({required this.fieldName, required this.validatorBuilder, this.autoFocus = true});
}

/// 表单验证器配置类，定义验证器的行为
class WFormValidatorsConfig {
  /// 是否显示边框错误
  bool _showBorderError = false;

  /// 自定义错误处理函数
  void Function(String fieldName, String error)? _customErrorHandler;

  /// 每一项校验的结果回调函数
  void Function(String fieldName, bool isValid, String? errorText)? _itemValidationCallback;

  /// 在校验前判断是否要跳过当前校验的回调函数
  bool Function(String fieldName, Map<String, dynamic>? formValues)? _shouldSkipValidation;

  /// 是否显示边框错误 setter
  set showBorderError(bool value) {
    _showBorderError = value;
  }

  /// 自定义错误处理函数 setter
  set customErrorHandler(Function(String fieldName, String error) value) {
    _customErrorHandler = value;
  }

  /// 每一项校验的结果回调函数 setter
  set itemValidationCallback(Function(String fieldName, bool isValid, String? errorText) value) {
    _itemValidationCallback = value;
  }

  /// 在校验前判断是否要跳过当前校验的回调函数 setter
  set shouldSkipValidation(bool Function(String fieldName, Map<String, dynamic>? formValues) value) {
    _shouldSkipValidation = value;
  }
}
