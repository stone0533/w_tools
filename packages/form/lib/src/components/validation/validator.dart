import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../form_data.dart';

/// 表单验证器类，用于管理和执行表单验证
///
/// 持有表单数据 [formData]、验证项列表 [validationItems] 与 [config]，
/// 由 [validate] 按顺序执行校验，行为由 [WFormValidatorConfig] 控制：
/// 短路 / 全量校验、是否显示边框错误、首个失败项的自动聚焦、
/// 错误提示回调的触发范围；校验结果可通过只读的 [errors] 获取。
///
/// 建议以本类作为统一校验入口：错误文案统一由 `WFormBorder` 展示，
/// 不会写入字段的 `errorText`（避免与 `InputDecoration` 双通道）。
/// 直接调用 `formKey.currentState.validate()` 时仍走原生字段错误展示，
/// 仅 text / dropdown 会渲染文案，自定义构建的字段不渲染。
class WFormValidator {
  /// 表单数据对象
  WFormData formData;

  /// 验证项列表
  List<WFormValidatorItem> validationItems;

  /// 验证器配置
  WFormValidatorConfig? config;

  /// 最近一次校验的失败项集合（字段名 -> 错误文本），只读快照
  ///
  /// 每次 [validate] 开始时清空并按校验结果重新填充，可用于汇总展示全部错误；
  /// 短路模式下只包含短路前已校验出的失败项。
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// 内部可变结果集合，由 [errors] 以只读快照对外暴露
  final Map<String, String> _errors = {};

  /// 创建表单验证器
  WFormValidator({required this.formData, required this.validationItems, this.config});

  /// 添加验证项
  void add(WFormValidatorItem item) {
    validationItems.add(item);
  }

  /// 执行验证，返回是否全部通过
  ///
  /// 默认短路校验：遇到第一个失败项即返回，不再校验后续字段；
  /// 当 [WFormValidatorConfig.continueOnError] 为 true 时改为全量校验，
  /// 会为所有失败项设置边框错误并触发相应回调。
  /// [WFormValidatorItem.autofocus] 仅作用于第一个失败项：其 autofocus 为 true 则聚焦、
  /// 为 false 则不聚焦（后续失败项一律不聚焦），且与是否显示边框错误无关。
  /// [WFormValidatorConfig.customErrorCallback] 默认只针对第一个失败项触发
  /// （避免全量校验时重复提示，例如连续弹出多个 toast），
  /// 可通过 [WFormValidatorConfig.notifyAllErrors] 改为对所有失败项触发。
  /// 校验开始时会清除本次参与校验字段的边框错误，避免短路提前返回或关闭
  /// [WFormValidatorConfig.showBorderError] 后残留旧错误。
  /// 校验项支持两种模式：`validatorBuilder` 自定义规则，或
  /// [WFormValidatorItem.field] 执行字段自身声明的 validator。
  /// 校验结果会写入 [errors]（字段名 -> 错误文本），可用于汇总展示全部错误。
  bool validate() {
    formData.closeKeyboard();
    final formKey = formData.formKey;
    formKey.currentState?.save();
    final resolvedConfig = config ??= WFormValidatorConfig();
    _errors.clear();

    // 先筛掉跳过项，并清除参与本次校验字段上一次残留的边框错误
    // （不依赖 showBorderError，保证短路提前返回 / 关闭提示后不残留旧红框）
    final items = <WFormValidatorItem>[];
    for (final item in validationItems) {
      final shouldSkip =
          resolvedConfig._shouldSkipValidation?.call(item.fieldName, formKey.currentState?.value) ??
          false;
      if (shouldSkip) continue;
      items.add(item);
      formData.clearError(item.fieldName);
    }

    bool allValid = true;
    bool focusedFirstError = false;
    bool notifiedFirstError = false;

    for (final item in items) {
      final String? errorText = _validateItem(item, formKey.currentState);
      final bool isValid = errorText == null;

      resolvedConfig._itemValidationCallback?.call(item.fieldName, isValid, errorText);

      if (errorText == null) continue;

      allValid = false;
      _errors[item.fieldName] = errorText;

      // 自动聚焦：仅第一个失败项生效，且与 showBorderError 无关
      if (!focusedFirstError) {
        focusedFirstError = true;
        if (item.autofocus == true) {
          formKey.currentState?.fields[item.fieldName]?.focus();
        }
      }

      if (resolvedConfig._showBorderError == true) {
        formData.setError(item.fieldName, errorTextList: [errorText]);
      }

      // 错误提示：默认只针对第一个失败项（避免全量校验时重复弹 toast）；
      // 配置 notifyAllErrors = true 后，每个失败项都会触发
      if (resolvedConfig._notifyAllErrors == true || !notifiedFirstError) {
        notifiedFirstError = true;
        resolvedConfig._customErrorCallback?.call(item.fieldName, errorText);
      }

      // 短路校验：默认遇第一个失败项即返回；continueOnError = true 时继续校验后续字段
      if (!resolvedConfig._continueOnError) {
        return false;
      }
    }
    return allValid;
  }

  /// 执行单个校验项，返回错误文本（null 表示通过）
  ///
  /// [WFormValidatorItem.validatorBuilder] 非空时执行自定义校验函数；
  /// 否则（[WFormValidatorItem.field] 模式）直接执行字段声明的 validator。
  /// 字段未注册或未声明 validator 时视为通过。
  String? _validateItem(WFormValidatorItem item, FormBuilderState? formState) {
    final builder = item.validatorBuilder;
    if (builder != null) {
      return builder().call(formState?.value[item.fieldName]);
    }

    // 字段泛型与 validator 参数类型在运行期才确定：全程按 dynamic 访问，
    // 避免 (String?) => String? 被强转为 (dynamic) => String?
    final dynamic formField = formState?.fields[item.fieldName];
    final dynamic validator = formField?.widget?.validator;
    if (validator == null) {
      return null;
    }
    // 直接调用 validator，不写入字段的 errorText：
    // 避免 InputDecoration 与 WFormBorder 同时展示错误（双通道）
    return validator.call(formState?.value[item.fieldName]) as String?;
  }
}

/// 表单验证项类，定义单个字段的验证规则
///
/// 支持两种模式：
/// - 自定义校验：[WFormValidatorItem] + `validatorBuilder`，可校验任意值组合；
/// - 字段校验器：[WFormValidatorItem.field]，执行字段自身声明的 `validator`，
///   并把校验错误汇总进 [WFormValidator.errors] 与边框错误。
class WFormValidatorItem {
  /// 字段名称
  String fieldName;

  /// 验证函数生成器
  ///
  /// 每次校验时调用一次以获取验证函数，便于按运行期状态生成动态规则；
  /// 若规则固定，可在生成器内返回同一函数实例，避免重复创建闭包。
  /// 为 null 时表示使用字段自身声明的 validator（见 [WFormValidatorItem.field]）。
  FormFieldValidator<dynamic> Function()? validatorBuilder;

  /// 是否自动聚焦到错误字段
  bool autofocus;

  /// 创建自定义校验项
  WFormValidatorItem({
    required this.fieldName,
    required this.validatorBuilder,
    this.autofocus = true,
  });

  /// 创建使用字段自身 validator 的校验项
  ///
  /// 校验时直接执行字段声明的 `validator`，不写入字段 `errorText`；
  /// 错误统一进入 [WFormValidator.errors] 与边框错误。
  /// 字段未注册或未声明 validator 时视为通过。
  WFormValidatorItem.field(
    this.fieldName, {
    this.autofocus = true,
  }) : validatorBuilder = null;
}

/// 表单验证器配置类，定义验证器的行为
///
/// 各选项通过 setter 配置，可用 [copy] / [copyWith] 生成副本
class WFormValidatorConfig {
  bool _showBorderError = false;
  bool _continueOnError = false;
  bool _notifyAllErrors = false;
  void Function(String fieldName, String error)? _customErrorCallback;
  void Function(String fieldName, bool isValid, String? errorText)? _itemValidationCallback;
  bool Function(String fieldName, Map<String, dynamic>? formValues)? _shouldSkipValidation;

  /// 设置是否显示边框错误
  ///
  /// 仅控制校验失败时是否设置边框错误；校验开始时的清除不受此开关影响
  set showBorderError(bool value) {
    _showBorderError = value;
  }

  /// 设置是否在遇到失败项后继续校验后续字段（默认 false，即短路校验）
  ///
  /// 保持默认时遇到第一个失败项立即返回；设为 true 改为全量校验，
  /// 遍历所有验证项并标记全部失败项
  set continueOnError(bool value) {
    _continueOnError = value;
  }

  /// 设置自定义错误处理函数（回调参数为：失败字段名、错误文本）
  set customErrorCallback(void Function(String fieldName, String error)? value) {
    _customErrorCallback = value;
  }

  /// 设置 [customErrorCallback] 是否对所有失败项触发（默认 false，只对第一个失败项触发）
  ///
  /// 设为 true 后，每个失败项都会调用一次 [customErrorCallback]；
  /// 配合全量校验可用于自行汇总或逐个提示全部错误
  set notifyAllErrors(bool value) {
    _notifyAllErrors = value;
  }

  /// 设置每一项校验的结果回调函数（回调参数为：字段名、是否通过、错误文本）
  ///
  /// 通过时错误文本为 null
  set itemValidationCallback(
    void Function(String fieldName, bool isValid, String? errorText)? value,
  ) {
    _itemValidationCallback = value;
  }

  /// 设置在校验前判断是否要跳过当前校验的回调函数（回调参数为：字段名、当前表单值）
  ///
  /// 返回 true 即跳过该字段：不校验、不触发回调、不参与边框错误处理
  set shouldSkipValidation(
    bool Function(String fieldName, Map<String, dynamic>? formValues)? value,
  ) {
    _shouldSkipValidation = value;
  }

  /// 创建当前配置的副本
  WFormValidatorConfig copy() => copyWith();

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormValidatorConfig copyWith({
    bool? showBorderError,
    bool? continueOnError,
    bool? notifyAllErrors,
    void Function(String fieldName, String error)? customErrorCallback,
    void Function(String fieldName, bool isValid, String? errorText)? itemValidationCallback,
    bool Function(String fieldName, Map<String, dynamic>? formValues)? shouldSkipValidation,
  }) {
    final config = WFormValidatorConfig();
    config._showBorderError = showBorderError ?? _showBorderError;
    config._continueOnError = continueOnError ?? _continueOnError;
    config._notifyAllErrors = notifyAllErrors ?? _notifyAllErrors;
    config._customErrorCallback = customErrorCallback ?? _customErrorCallback;
    config._itemValidationCallback = itemValidationCallback ?? _itemValidationCallback;
    config._shouldSkipValidation = shouldSkipValidation ?? _shouldSkipValidation;
    return config;
  }
}
