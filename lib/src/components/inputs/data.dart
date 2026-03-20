import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';

import 'border.dart';
import 'validators.dart';

/// 表单数据管理类，用于管理表单状态、错误处理和数据操作
class WFormData {
  WFormBorderConfig? formBorderConfig;

  /// 构造函数
  ///
  /// @param formBorderConfig 表单边框配置
  WFormData({this.formBorderConfig});

  /// 表单 key
  var formKey = GlobalKey<FormBuilderState>();

  /// 获取表单字段
  FormBuilderFields? get fields => formKey.currentState?.fields;

  /// 获取表单值
  Map<String, dynamic>? get value => formKey.currentState?.value;

  /// 字段输入状态映射
  Map<String, bool> formEntered = {};

  /// 检查是否所有字段都已输入
  ///
  /// @param length 字段总数
  /// @return 是否所有字段都已输入
  bool isAllEntered(int length) {
    return (formEntered.length == length) && (formEntered.containsValue(false) == false);
  }

  /// 字段错误样式状态映射
  Map<String, bool> formShowErrorStyle = {};

  /// 检查当前字段是否需要显示错误样式
  ///
  /// @param name 字段名称
  /// @return 是否需要显示错误样式
  bool isShowErrorStyle(String name) {
    return formShowErrorStyle[name] ?? false;
  }

  /// 设置字段数据
  ///
  /// @param name 字段名称
  /// @param value 字段值
  void didChange<T>(String name, T value) {
    formKey.currentState?.fields[name]?.didChange(value);
  }

  /// 内容修改后触发的回调
  ///
  /// @param name 字段名称
  /// @param value 字段值
  /// @param updateList 需要更新的字段列表
  /// @param callback 回调函数
  void onChange<T>(
    String name,
    T? value, {
    List<String>? updateList,
    VoidCallback? callback,
  }) {
    formBorderKeys[name]?.currentState?.setError(false);
    if (value is String) {
      String? v = value;
      formEntered[name] = v.isNotEmpty;
      formShowErrorStyle[name] = false;
    }
    callback?.call();
  }

  /// 获取字段的值
  ///
  /// @param name 字段名称
  /// @return 字段值
  dynamic getFieldsValue(String name) {
    return formKey.currentState?.fields[name]?.value;
  }

  /// 设置错误样式
  ///
  /// @param name 字段名称
  /// @param errorList 错误列表
  /// @param callback 回调函数
  void setError(
    String name, {
    Map<String, List<String>>? errorList,
    VoidCallback? callback,
  }) {
    formShowErrorStyle[name] = true;
    errorList?.entries.forEach((a) {
      formBorderKeys[a.key]?.currentState?.setError(
        true,
        errorTextList: a.value,
      );
    });
    callback?.call();
  }

  /// 表单边框 key 映射
  Map<String, GlobalKey<WFormBorderState>> formBorderKeys = {};

  /// 获取表单边框 key
  ///
  /// @param name 字段名称
  /// @return 表单边框 key
  GlobalKey<WFormBorderState> getFormBorderKey(String name) {
    if (formBorderKeys.containsKey(name) == false) {
      formBorderKeys[name] = GlobalKey<WFormBorderState>();
    }
    return formBorderKeys[name]!;
  }

  /// 关闭键盘
  void closeKeyboard() {
    Get.focusScope?.unfocus();
  }

  /// 创建表单验证器
  ///
  /// @param config 验证器配置
  /// @param items 验证项列表
  /// @return WFormValidators 实例
  WFormValidators validators({WFormValidatorsConfig? config, List<WFormValidatorsItem>? items}) {
    return WFormValidators(
      formData: this,
      validationItems: items ?? [],
      config: config,
    );
  }
}
