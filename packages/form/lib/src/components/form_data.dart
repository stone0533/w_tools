import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border.dart';
import 'validation/validator.dart';

/// 表单数据管理类
///
/// 持有表单 [formKey]，并提供：
/// - 字段值读写：[value]、[didChange]、[getFieldsValue]（[fields] 为底层字段集合）
/// - 输入状态：[formEntered]、[isAllEntered]
/// - 边框错误：[setError]、[clearError]、[ensureBorderKey]（配合 [formBorderKeys]）
/// - 校验器工厂：[validators]
class WFormData {
  /// 创建表单数据容器
  WFormData();

  /// 表单 key
  final formKey = GlobalKey<FormBuilderState>();

  /// 表单字段集合（表单未挂载时为 null）
  FormBuilderFields? get fields => formKey.currentState?.fields;

  /// 表单值（表单未挂载时返回空表）
  Map<String, dynamic> get value => formKey.currentState?.value ?? const <String, dynamic>{};

  /// 各字段是否已输入的映射
  final Map<String, bool> formEntered = {};

  /// 是否所有字段都已输入
  ///
  /// [length] 需与实际参与判断的字段总数一致。
  /// 已卸载字段残留在 [formEntered] 中的陈旧记录会被忽略，
  /// 避免关闭弹窗 / 动态移除字段后本方法恒为 false。
  bool isAllEntered(int length) {
    final registered = fields;
    if (registered == null) {
      return formEntered.length == length && !formEntered.containsValue(false);
    }
    final entries = formEntered.entries.where((e) => registered.containsKey(e.key)).toList();
    return entries.length == length && !entries.any((e) => !e.value);
  }

  /// 按字段名设置字段值
  ///
  /// 仅写入字段状态，不会更新 [formEntered]；需要同步输入状态时
  /// 请改用 [onChange]。
  void didChange<T>(String name, T value) {
    formKey.currentState?.fields[name]?.didChange(value);
  }

  /// 处理字段内容变更：清除该字段的错误样式并更新输入状态
  ///
  /// [formEntered] 判定规则：字符串 / 集合 / Map 按非空，
  /// 布尔按自身值，其它类型按非 null。
  void onChange<T>(
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
  /// 需要该字段已通过 `WFormBorderWithData` / `withFormBorder` 注册边框；
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

  /// 关闭键盘
  void closeKeyboard() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  /// 创建表单校验器（校验项由 [WFormValidator.validate] 按序执行）
  WFormValidator validators({WFormValidatorConfig? config, List<WFormValidatorItem>? items}) {
    return WFormValidator(
      formData: this,
      validationItems: items ?? [],
      config: config,
    );
  }
}
