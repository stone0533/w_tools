import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'data.dart';

/// 表单数据继承组件，用于在 widget 树中传递 WFormData
class _WFormDataInherited extends InheritedWidget {
  final WFormData formData;

  const _WFormDataInherited({
    required this.formData,
    required super.child,
  });

  @override
  bool updateShouldNotify(_WFormDataInherited oldWidget) {
    return formData != oldWidget.formData;
  }
}

/// 表单构建器组件，用于创建和管理表单
class WFormBuilder extends StatelessWidget {
  /// 表单数据对象
  final WFormData formData;

  /// 子组件
  final Widget child;

  /// 自动验证模式
  final AutovalidateMode? autovalidateMode;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param formData 表单数据对象
  /// @param child 子组件
  /// @param autovalidateMode 自动验证模式
  const WFormBuilder({
    super.key,
    required this.formData,
    required this.child,
    this.autovalidateMode,
  });

  /// 通过上下文获取 WFormData 实例
  ///
  /// @param context 上下文
  /// @return WFormData 实例
  static WFormData? of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_WFormDataInherited>();
    return inherited?.formData;
  }

  @override
  Widget build(BuildContext context) {
    return _WFormDataInherited(
      formData: formData,
      child: FormBuilder(
        key: formData.formKey,
        autovalidateMode: autovalidateMode,
        child: child,
      ),
    );
  }
}
