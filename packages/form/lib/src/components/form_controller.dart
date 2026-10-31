import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border.dart';
import 'validation/validator.dart';

/// 表单数据管理类
///
/// 持有表单 [formKey]，并提供：
/// - 字段值读写：[value]、[setValue]、[getFieldsValue]（[fields] 为底层字段集合）
/// - 输入状态：[formEntered]、[isAllEntered]
/// - 边框错误：[setError]、[clearError]、[ensureBorderKey]（配合 [formBorderKeys]）
/// - 校验器工厂：[validators]
class WFormController {
  /// 创建表单数据容器
  WFormController();

  /// 表单 key
  final formKey = GlobalKey<FormBuilderState>();

  /// 表单字段集合（表单未挂载时为 null）
  FormBuilderFields? get fields => formKey.currentState?.fields;

  /// 表单值（表单未挂载时返回空表）
  Map<String, dynamic> get value => formKey.currentState?.value ?? const <String, dynamic>{};

  /// 各字段是否已输入的映射
  final Map<String, bool> formEntered = {};

  /// 指定字段是否都已输入
  ///
  /// 用字段名显式表达判断范围，避免传错数量；空集合返回 false。
  /// 字段卸载后 [formEntered] 会被清理，因此动态字段不会残留。
  bool isAllEntered(Iterable<String> fieldNames) {
    if (fieldNames.isEmpty) return false;
    pruneFormEntered();
    for (final name in fieldNames) {
      if (formEntered[name] != true) return false;
    }
    return true;
  }

  /// 清理已卸载字段在 [formEntered] 中的残留记录
  void pruneFormEntered() {
    final registered = fields;
    if (registered == null) return;
    formEntered.removeWhere((name, _) => !registered.containsKey(name));
  }

  /// 按字段名设置字段值
  ///
  /// 仅写入字段状态，不会更新 [formEntered]；需要同步输入状态时
  /// 请改用 [handleChange]。
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
    formEntered[name] = switch (value) {
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
  /// 需要该字段已通过 `WFormFieldShell` / `withFormBorder` 注册边框；
  /// [errorTextList] 会交给边框的 `errorBuilder` 渲染。
  void setError(
    String name, {
    List<String>? errorTextList,
    VoidCallback? callback,
  }) {
    formBorderKeys[name]?.currentState?.setError(
      true,
      errorTextList: errorTextList,
    );
    callback?.call();
  }

  /// 清除指定字段的错误样式
  void clearError(String name) {
    formBorderKeys[name]?.currentState?.setError(false);
  }

  /// 表单边框 key 映射（由 [ensureBorderKey] 按需登记）
  final Map<String, GlobalKey<WFormBorderState>> formBorderKeys = {};

  /// 获取指定字段的边框 key，不存在时创建
  GlobalKey<WFormBorderState> ensureBorderKey(String name) {
    return formBorderKeys.putIfAbsent(name, () => GlobalKey<WFormBorderState>());
  }

  /// 注销指定字段的边框 key；字段卸载时由 WFormFieldShell 调用
  void removeBorderKey(String name) {
    formBorderKeys.remove(name);
  }

  /// 注销指定字段的输入状态；字段卸载时由 WFormFieldShell 调用
  void removeFormEntered(String name) {
    formEntered.remove(name);
  }

  /// 关闭键盘
  void closeKeyboard() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  /// 创建表单校验器（校验项由 [WFormValidator.validate] 按序执行）
  WFormValidator validators({WFormValidatorSettings? settings, List<WFormValidatorItem>? items}) {
    return WFormValidator(
      formData: this,
      validationItems: items ?? [],
      settings: settings,
    );
  }

  /// 一步执行校验
  ///
  /// [items] 为 null 时自动使用当前已挂载字段的自身 validator。
  /// 业务表单优先用本方法或 [validators]，避免直接调用 formKey.validate()
  /// 造成两套错误通道。
  bool validate({WFormValidatorSettings? settings, List<WFormValidatorItem>? items}) {
    if (formKey.currentState == null) return false;
    pruneFormEntered();
    final validationItems =
        items ??
        (fields?.keys.map(WFormValidatorItem.field).toList(growable: false) ??
            const <WFormValidatorItem>[]);
    return validators(items: validationItems, settings: settings).validate();
  }
}
