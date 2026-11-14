import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border_access.dart';
import 'form_settings.dart';
import 'validation/validator.dart';

/// 表单数据管理类
///
/// 持有表单 [formKey]，并提供：
/// - 字段值读写：[value]、[setValue]、[getFieldsValue]（[fields] 为底层字段集合）
/// - 边框错误：[setError]、[clearError]（通道由包内 registry 维护）
/// - 校验器工厂：[validators]
class WFormController {
  /// 创建表单数据容器
  WFormController();

  /// 表单 key
  final formKey = GlobalKey<FormBuilderState>();

  /// 当前子树中的 [WFormController]（无 `WForm` / `WFormScope` 祖先时返回 null）
  static WFormController? of(BuildContext context) => WFormControllerScope.of(context);

  /// 当前子树中的 [WFormController]，没有祖先时抛 [StateError]
  static WFormController requireOf(BuildContext context) {
    final formData = of(context);
    if (formData == null) {
      throw StateError('WFormScope 未找到');
    }
    return formData;
  }

  /// `WForm` 注入的默认校验设置（只读）；未显式传 settings 时使用。
  ///
  /// 写入口只有 `WForm(validatorSettings:)`；不要在 controller 上二次覆盖。
  WFormValidatorSettings? get validatorSettings => formValidatorSettingsOf(this);

  /// 表单字段集合（表单未挂载时为 null）
  FormBuilderFields? get fields => formKey.currentState?.fields;

  /// 字段名拼错时在 debug 直接报出来；未挂载时不做判断。
  void _assertFieldExists(String name) {
    assert(
      formKey.currentState == null || (fields?.containsKey(name) ?? false),
      '字段 $name 不存在：检查 name 是否与字段声明一致（或字段尚未挂载）。',
    );
  }

  /// 表单实时值（字段 `didChange` 后立即反映；表单未挂载时返回空表）
  Map<String, dynamic> get value => formKey.currentState?.instantValue ?? const <String, dynamic>{};

  /// 上次显式 [save] 时的快照（旧 `value` 语义）
  Map<String, dynamic> get savedValue => formKey.currentState?.value ?? const <String, dynamic>{};

  /// 保存当前值（触发字段 `onSaved`）；`validate()` 不再隐式调用。
  void save() {
    formKey.currentState?.save();
  }

  /// 按字段名设置字段值，并清除该字段的边框错误
  ///
  /// 只用于程序化改值；不要在字段自己的 `onChanged` 里回写同一字段。
  /// 字段值已由 FormBuilder 更新；同值回写会 no-op，避免
  /// didChange → onChanged → setValue 的递归。
  void setValue<T>(String name, T value) {
    _assertFieldExists(name);
    clearError(name);
    final field = formKey.currentState?.fields[name];
    if (field == null) return;
    if (field.value == value) return;
    field.didChange(value);
  }

  /// 把指定字段重置回它自己的 `initialValue`
  ///
  /// 适用于非空值类型：`bool` → 初值（含 `false`）、`Set<T>` → 初值集合、
  /// 日期 / 下拉 → 初值。等价于对该字段调用 `FormFieldState.reset()`，
  /// 因此字段自己声明的 `onReset` 也会执行。
  void resetValue(String name) {
    _assertFieldExists(name);
    formKey.currentState?.fields[name]?.reset();
  }

  /// 重置表单：所有字段回到各自初始值
  ///
  /// 等价于 `formKey.currentState?.reset()`，封装以避免业务代码直接操作
  /// [formKey]。
  void reset() {
    formKey.currentState?.reset();
  }

  /// 获取字段的即时值（无需先 save）
  ///
  /// 实际类型与 [T] 不符时抛错；字段名拼错时在 debug 断言。
  T? getFieldsValue<T>(String name) {
    _assertFieldExists(name);
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
    final registry = bordersOf(this);
    assert(
      registry.has(name) || !(fields?.containsKey(name) ?? false),
      '字段 $name 没有边框（bordered: false 的字段不会渲染 setError）；'
      '这类字段的错误请从 WFormValidator.errors 读取。',
    );
    if (registry.has(name)) {
      registry.channelOf(name).value = errorTextList ?? const <String>[];
    }
    callback?.call();
  }

  /// 清除指定字段的错误样式
  void clearError(String name) {
    bordersOf(this).clearChannel(name);
  }

  /// 创建表单校验器（校验项由 [WFormValidator.validate] 按序执行）
  ///
  /// [items] 为 null 时与 [validate] 一致：校验当前已挂载字段的自身 validator。
  /// 表单未挂载时：字段校验项 / 空校验项返回 false；纯自定义 `validatorBuilder`
  /// 仍然可以运行。
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
  /// 校验不会隐式 `save()`；需要保存时单独调用 [save]。
  bool validate({WFormValidatorSettings? settings, List<WFormValidatorItem>? items}) {
    if (formKey.currentState == null) return false;
    final validationItems =
        items ?? (fields?.keys.map(WFormValidatorItem.field).toList() ?? <WFormValidatorItem>[]);
    return validators(items: validationItems, settings: settings ?? validatorSettings).validate();
  }
}

/// 包内：把 [WFormController] 放进 widget 子树，由 `WFormScope` 装配。
class WFormControllerScope extends InheritedWidget {
  /// 表单数据对象
  final WFormController formData;

  /// 创建 controller 作用域
  const WFormControllerScope({
    super.key,
    required this.formData,
    required super.child,
  });

  /// 读取最近的 controller（无祖先时返回 null）
  static WFormController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WFormControllerScope>()?.formData;

  @override
  bool updateShouldNotify(WFormControllerScope oldWidget) => formData != oldWidget.formData;
}
