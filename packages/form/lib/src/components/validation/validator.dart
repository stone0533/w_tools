import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../form_controller.dart';

/// 表单验证器类，用于管理和执行表单验证
///
/// 持有表单数据 [formData]、验证项列表 [validationItems] 与 [settings]，
/// 由 [validate] 按顺序执行校验，行为由 [WFormValidatorSettings] 控制：
/// 短路 / 全量校验、是否显示边框错误、首个失败项的自动聚焦、
/// 错误提示回调的触发范围；校验结果可通过只读的 [errors] 获取。
///
/// 建议以本类作为统一校验入口：错误文案统一由 `WFormBorder` 展示，
/// 不会写入字段的 `errorText`（避免与 `InputDecoration` 双通道）。
/// 直接调用 `formKey.currentState.validate()` 时仍走原生字段错误展示，
/// 仅 text / dropdown 会渲染文案，自定义构建的字段不渲染。
class WFormValidator {
  /// 表单数据对象
  WFormController formData;

  /// 验证项列表
  List<WFormValidatorItem> validationItems;

  /// 验证器配置
  WFormValidatorSettings? settings;

  /// 最近一次校验的失败项集合（字段名 -> 错误文本），只读快照
  ///
  /// 每次 [validate] 开始时清空并按校验结果重新填充，可用于汇总展示全部错误；
  /// 短路模式下只包含短路前已校验出的失败项。
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// 内部可变结果集合，由 [errors] 以只读快照对外暴露
  final Map<String, String> _errors = {};

  /// 创建表单验证器
  WFormValidator({required this.formData, required this.validationItems, this.settings});

  /// 添加验证项
  void add(WFormValidatorItem item) {
    validationItems.add(item);
  }

  /// 执行验证，返回是否全部通过
  ///
  /// 默认短路校验：遇到第一个失败项即返回，不再校验后续字段；
  /// 当 [WFormValidatorSettings.continueOnError] 为 true 时改为全量校验，
  /// 会为所有失败项设置边框错误并触发相应回调。
  /// [WFormValidatorItem.autofocus] 仅作用于第一个失败项：其 autofocus 为 true 则聚焦、
  /// 为 false 则不聚焦（后续失败项一律不聚焦），且与是否显示边框错误无关。
  /// [WFormValidatorSettings.customErrorCallback] 默认只针对第一个失败项触发
  /// （避免全量校验时重复提示，例如连续弹出多个 toast），
  /// 可通过 [WFormValidatorSettings.notifyAllErrors] 改为对所有失败项触发。
  /// 校验开始时会清除本次参与校验字段的边框错误，避免短路提前返回或关闭
  /// [WFormValidatorSettings.showBorderError] 后残留旧错误。
  /// 校验项支持两种模式：`validatorBuilder` 自定义规则，或
  /// [WFormValidatorItem.field] 执行字段自身声明的 validator。
  /// 校验结果会写入 [errors]（字段名 -> 错误文本），可用于汇总展示全部错误。
  bool validate() {
    formData.closeKeyboard();
    final formKey = formData.formKey;
    formKey.currentState?.save();
    final resolvedConfig = settings ??= formData.validatorSettings ?? WFormValidatorSettings();
    _errors.clear();

    // 先筛掉跳过项，并清除参与本次校验字段上一次残留的边框错误
    // （不依赖 showBorderError，保证短路提前返回 / 关闭提示后不残留旧红框）
    final items = <WFormValidatorItem>[];
    for (final item in validationItems) {
      final shouldSkip =
          resolvedConfig.shouldSkipValidation?.call(item.fieldName, formKey.currentState?.value) ??
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

      resolvedConfig.itemValidationCallback?.call(item.fieldName, isValid, errorText);

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

      if (resolvedConfig.showBorderError == true && formData.hasBorder(item.fieldName)) {
        formData.setError(item.fieldName, errorTextList: [errorText]);
      }

      // 错误提示：默认只针对第一个失败项（避免全量校验时重复弹 toast）；
      // 配置 notifyAllErrors = true 后，每个失败项都会触发
      if (resolvedConfig.notifyAllErrors == true || !notifiedFirstError) {
        notifiedFirstError = true;
        resolvedConfig.customErrorCallback?.call(item.fieldName, errorText);
      }

      // 短路校验：默认遇第一个失败项即返回；continueOnError = true 时继续校验后续字段
      if (!resolvedConfig.continueOnError) {
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
  final String fieldName;

  /// 验证函数生成器
  ///
  /// 每次校验时调用一次以获取验证函数，便于按运行期状态生成动态规则；
  /// 若规则固定，可在生成器内返回同一函数实例，避免重复创建闭包。
  /// 为 null 时表示使用字段自身声明的 validator（见 [WFormValidatorItem.field]）。
  final FormFieldValidator<dynamic> Function()? validatorBuilder;

  /// 是否自动聚焦到错误字段
  final bool autofocus;

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
/// 各选项通过可变字段配置，可用 [copy] / [copyWith] 生成副本
class WFormValidatorSettings {
  /// 是否显示边框错误
  ///
  /// 仅控制校验失败时是否设置边框错误；校验开始时的清除不受此开关影响。
  bool showBorderError = false;

  /// 遇到失败项后是否继续校验后续字段（默认 false，即短路校验）
  bool continueOnError = false;

  /// 是否对所有失败项触发 [customErrorCallback]
  bool notifyAllErrors = false;

  /// 自定义错误处理函数（失败字段名、错误文本）
  void Function(String fieldName, String error)? customErrorCallback;

  /// 每一项校验的结果回调（字段名、是否通过、错误文本）
  void Function(String fieldName, bool isValid, String? errorText)? itemValidationCallback;

  /// 校验前判断是否跳过当前字段
  bool Function(String fieldName, Map<String, dynamic>? formValues)? shouldSkipValidation;

  /// 创建当前配置的副本
  WFormValidatorSettings copy() => copyWith();

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormValidatorSettings copyWith({
    bool? showBorderError,
    bool? continueOnError,
    bool? notifyAllErrors,
    void Function(String fieldName, String error)? customErrorCallback,
    void Function(String fieldName, bool isValid, String? errorText)? itemValidationCallback,
    bool Function(String fieldName, Map<String, dynamic>? formValues)? shouldSkipValidation,
  }) {
    final config = WFormValidatorSettings();
    config.showBorderError = showBorderError ?? this.showBorderError;
    config.continueOnError = continueOnError ?? this.continueOnError;
    config.notifyAllErrors = notifyAllErrors ?? this.notifyAllErrors;
    config.customErrorCallback = customErrorCallback ?? this.customErrorCallback;
    config.itemValidationCallback = itemValidationCallback ?? this.itemValidationCallback;
    config.shouldSkipValidation = shouldSkipValidation ?? this.shouldSkipValidation;
    return config;
  }
}

/// WFormValidatorSettings 的 Builder。
///
/// 当前阶段仍返回可变 Config 的副本；后续 Config 不可变化后保持同一调用方式。
