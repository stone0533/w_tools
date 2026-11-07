import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border_registry.dart';
import 'validation/validator.dart';

/// 表单数据管理类
///
/// 持有表单 [formKey]，并提供：
/// - 字段值读写：[value]、[setValue]、[getFieldsValue]（[fields] 为底层字段集合）
/// - 输入状态：[formEntered]、[isAllEntered]
/// - 边框错误：[setError]、[clearError]（通道登记在内部 `borders`）
/// - 校验器工厂：[validators]
class WFormController {
  /// 创建表单数据容器
  WFormController();

  /// 表单 key
  final formKey = GlobalKey<FormBuilderState>();

  /// WForm 提供的默认校验设置；未显式传 settings 时使用。
  WFormValidatorSettings? validatorSettings;

  /// 表单字段集合（表单未挂载时为 null）
  FormBuilderFields? get fields => formKey.currentState?.fields;

  /// 表单实时值（字段 `didChange` 后立即反映；表单未挂载时返回空表）
  Map<String, dynamic> get value => formKey.currentState?.instantValue ?? const <String, dynamic>{};

  /// 上次 `validate()` / `save()` 时的快照（旧 `value` 语义）
  Map<String, dynamic> get savedValue => formKey.currentState?.value ?? const <String, dynamic>{};

  /// 各字段是否已输入的映射（**由当前字段值实时派生**，只读）
  ///
  /// 判定规则：字符串 / 集合 / Map 按非空，布尔按自身值，其它类型按非 null。
  /// 不再依赖字段自觉调用 [handleChange]，自定义字段也能被正确反映。
  Map<String, bool> get formEntered {
    final registered = fields;
    if (registered == null) return const <String, bool>{};
    return {
      for (final name in registered.keys) name: _isEntered(registered[name]?.value),
    };
  }

  static bool _isEntered(Object? value) => switch (value) {
    String v => v.isNotEmpty,
    Iterable v => v.isNotEmpty,
    Map v => v.isNotEmpty,
    bool v => v,
    _ => value != null,
  };

  /// 指定字段是否都已输入
  ///
  /// 用字段名显式表达判断范围，避免传错数量；空集合返回 false。
  /// 字段卸载后 [formEntered] 会被清理，因此动态字段不会残留。
  bool isAllEntered(Iterable<String> fieldNames) {
    if (fieldNames.isEmpty) return false;
    final registered = fields;
    if (registered == null) return false;
    for (final name in fieldNames) {
      if (!_isEntered(registered[name]?.value)) return false;
    }
    return true;
  }

  /// 按字段名设置字段值
  ///
  /// 直接调用字段的 `didChange`：值写入后 [formEntered] 会立即反映
  /// （它按当前字段值实时派生，没有需要手工维护的输入状态）。
  void setValue<T>(String name, T value) {
    formKey.currentState?.fields[name]?.didChange(value);
  }

  /// 写入字段值并清除该字段的边框错误
  ///
  /// 等价于 [setValue] + [handleChange]；[formEntered] 由字段值实时派生，
  /// 两种写法都会反映，`updateValue` 只是顺带清掉上一次的边框错误。
  void updateValue<T>(String name, T value) {
    setValue<T>(name, value);
    handleChange<T>(name, value);
  }

  /// 清空指定字段：把值写成 `null` 并更新输入状态
  ///
  /// 只对**可空类型**（String / 数值等）语义明确；`bool` / `Set` 这类非空值类型
  /// 请用 [resetValue] 回到字段自己的 `initialValue`。
  void clearValue(String name) {
    updateValue<String?>(name, null);
  }

  /// 把指定字段重置回它自己的 `initialValue`
  ///
  /// 适用于非空值类型：`bool` → 初值（含 `false`）、`Set<String>` → 初值集合、
  /// 日期 / 下拉 → 初值。等价于对该字段调用 `FormFieldState.reset()`，
  /// 因此字段自己声明的 `onReset` 也会执行。
  void resetValue(String name) {
    formKey.currentState?.fields[name]?.reset();
  }

  /// 重置表单：所有字段回到各自初始值
  ///
  /// 等价于 `formKey.currentState?.reset()`，封装以避免业务代码直接操作
  /// [formKey]。[formEntered] 按字段值派生，reset 后自动复位。
  void reset() {
    formKey.currentState?.reset();
  }

  /// 处理字段内容变更：清除该字段的错误样式
  ///
  /// [formEntered] 不依赖本方法（它按字段值实时派生）；保留参数是为了兼容
  /// 既有调用与 `callback` 时机。
  void handleChange<T>(
    String name,
    T? value, {
    VoidCallback? callback,
  }) {
    clearError(name);
    callback?.call();
  }

  /// 获取字段的即时值（无需先 save）
  ///
  /// 实际类型与 [T] 不符时抛错。
  T? getFieldsValue<T>(String name) {
    return formKey.currentState?.fields[name]?.value as T?;
  }

  /// 内部：字段边框 / 错误通道登记
  ///
  /// 包内实现（`WFormFieldShell`、`WFormBorder` 使用）；业务侧请用
  /// [setError] / [clearError]，不要直接操作通道。
  @internal
  final WFormBorderRegistry borders = WFormBorderRegistry();

  /// 设置指定字段的错误样式
  ///
  /// 需要该字段已通过 `WFormFieldShell` 注册边框；
  /// [errorTextList] 会交给边框的 `errorBuilder` 渲染。
  void setError(
    String name, {
    List<String>? errorTextList,
    VoidCallback? callback,
  }) {
    assert(
      borders.has(name) || !(fields?.containsKey(name) ?? false),
      '字段 $name 没有边框（bordered: false 的字段不会渲染 setError）；'
      '这类字段的错误请从 WFormValidator.errors 读取。',
    );
    if (borders.has(name)) {
      borders.channelOf(name).value = errorTextList ?? const <String>[];
    }
    callback?.call();
  }

  /// 清除指定字段的错误样式
  void clearError(String name) {
    borders.clearChannel(name);
  }

  /// 关闭键盘
  void closeKeyboard() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  /// 创建表单校验器（校验项由 [WFormValidator.validate] 按序执行）
  ///
  /// [items] 为 null 时与 [validate] 一致：校验当前已挂载字段的自身 validator。
  /// 表单未挂载时按空校验项处理（调用 [WFormValidator.validate] 会通过）。
  WFormValidator validators({WFormValidatorSettings? settings, List<WFormValidatorItem>? items}) {
    final validationItems =
        items ?? (fields?.keys.map(WFormValidatorItem.field).toList() ?? <WFormValidatorItem>[]);
    return WFormValidator(
      formData: this,
      validationItems: validationItems,
      settings: settings ?? validatorSettings,
    );
  }

  /// 一步执行校验
  ///
  /// [items] 为 null 时自动使用当前已挂载字段的自身 validator。
  /// 业务表单优先用本方法或 [validators]，避免直接调用 formKey.validate()
  /// 造成两套错误通道。
  ///
  /// 表单未挂载时返回 false；已挂载但没有字段时按“无错误”返回 true。
  bool validate({WFormValidatorSettings? settings, List<WFormValidatorItem>? items}) {
    if (formKey.currentState == null) return false;
    final validationItems =
        items ?? (fields?.keys.map(WFormValidatorItem.field).toList() ?? <WFormValidatorItem>[]);
    return validators(items: validationItems, settings: settings ?? validatorSettings).validate();
  }
}
