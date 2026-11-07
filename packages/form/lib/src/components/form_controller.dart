import 'dart:collection';

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border_registry.dart' as border_registry;
import 'validation/validator.dart';

/// 表单数据管理类
///
/// 持有表单 [formKey]，并提供：
/// - 字段值读写：[value]、[setValue]、[getFieldsValue]（[fields] 为底层字段集合）
/// - 输入状态：[formEntered]、[isAllEntered]
/// - 边框错误：[setError]、[clearError]、[hasBorder]
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

  /// 各字段是否已输入的映射（只读视图；写入走 [handleChange] / [updateValue]）
  Map<String, bool> get formEntered => UnmodifiableMapView(_formEntered);
  final Map<String, bool> _formEntered = {};

  /// 指定字段是否都已输入
  ///
  /// 用字段名显式表达判断范围，避免传错数量；空集合返回 false。
  /// 字段卸载后 [formEntered] 会被清理，因此动态字段不会残留。
  bool isAllEntered(Iterable<String> fieldNames) {
    if (fieldNames.isEmpty) return false;
    pruneFormEntered();
    for (final name in fieldNames) {
      if (_formEntered[name] != true) return false;
    }
    return true;
  }

  /// 清理已卸载字段在 [formEntered] 中的残留记录
  void pruneFormEntered() {
    final registered = fields;
    if (registered == null) return;
    _formEntered.removeWhere((name, _) => !registered.containsKey(name));
  }

  /// 按字段名设置字段值
  ///
  /// 直接调用字段的 `didChange`：值会写入，但不保证更新 [formEntered] ——
  /// 包内字段实现了 `onChanged`（会同步），自定义字段不一定。
  /// 需要确保输入状态同步时用 [updateValue]。
  void setValue<T>(String name, T value) {
    formKey.currentState?.fields[name]?.didChange(value);
  }

  /// 同时写入字段值并更新输入状态
  ///
  /// 等价于 [setValue] + [handleChange]，业务代码修改已有字段时优先使用本方法，
  /// 避免只更新值而忘记维护 [formEntered]。
  void updateValue<T>(String name, T value) {
    setValue<T>(name, value);
    handleChange<T>(name, value);
  }

  /// 清空指定字段并更新输入状态
  void clearValue(String name) {
    updateValue<String?>(name, null);
  }

  /// 重置表单：所有字段回到各自初始值
  ///
  /// 等价于 `formKey.currentState?.reset()`，封装以避免业务代码直接操作
  /// [formKey]。字段的 `formEntered` 会随各字段的 `didChange` 复位；
  /// 未实现 `onChanged` 的自定义字段不保证同步，可用 [pruneFormEntered] 兜底。
  void reset() {
    formKey.currentState?.reset();
  }

  /// 处理字段内容变更：清除该字段的错误样式并更新输入状态
  ///
  /// [formEntered] 判定规则：字符串 / 集合 / Map 按非空，
  /// 布尔按自身值，其它类型按非 null。
  void handleChange<T>(
    String name,
    T? value, {
    VoidCallback? callback,
  }) {
    clearError(name);
    _formEntered[name] = switch (value) {
      String v => v.isNotEmpty,
      Iterable v => v.isNotEmpty,
      Map v => v.isNotEmpty,
      bool v => v,
      _ => value != null,
    };
    callback?.call();
  }

  /// 获取字段的即时值（无需先 save）
  ///
  /// 实际类型与 [T] 不符时抛错。
  T? getFieldsValue<T>(String name) {
    return formKey.currentState?.fields[name]?.value as T?;
  }

  /// 设置指定字段的错误样式
  ///
  /// 需要该字段已通过 `WFormFieldShell` 注册边框；
  /// [errorTextList] 会交给边框的 `errorBuilder` 渲染。
  void setError(
    String name, {
    List<String>? errorTextList,
    VoidCallback? callback,
  }) {
    final borderKey = border_registry.borderKeyOf(this, name);
    assert(
      borderKey != null || !(fields?.containsKey(name) ?? false),
      '字段 $name 没有边框 key（bordered: false 的字段不会渲染 setError）；'
      '这类字段的错误请从 WFormValidator.errors 读取。',
    );
    borderKey?.currentState?.setError(
      true,
      errorTextList: errorTextList,
    );
    callback?.call();
  }

  /// 清除指定字段的错误样式
  void clearError(String name) {
    border_registry.borderKeyOf(this, name)?.currentState?.setError(false);
  }

  /// 内部：该字段是否已注册边框（`bordered: false` 的字段没有）。
  @internal
  bool hasBorder(String name) => border_registry.hasBorder(this, name);

  /// 注销指定字段的输入状态；字段卸载时由 WFormFieldShell 调用
  void removeFormEntered(String name) {
    _formEntered.remove(name);
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
        items ??
        (fields?.keys.map(WFormValidatorItem.field).toList(growable: false) ??
            const <WFormValidatorItem>[]);
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
    pruneFormEntered();
    final validationItems =
        items ??
        (fields?.keys.map(WFormValidatorItem.field).toList(growable: false) ??
            const <WFormValidatorItem>[]);
    return validators(items: validationItems, settings: settings ?? validatorSettings).validate();
  }
}
