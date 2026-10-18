import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border.dart';
import 'form_data.dart';

/// 表单数据继承组件，用于在 widget 树中传递 WFormData 与表单边框配置
class _WFormDataInherited extends InheritedWidget {
  /// 表单数据对象
  final WFormData formData;

  /// 表单边框配置
  final WFormBorderConfig? formBorderConfig;

  const _WFormDataInherited({
    required this.formData,
    required this.formBorderConfig,
    required super.child,
  });

  @override
  bool updateShouldNotify(_WFormDataInherited oldWidget) {
    return formData != oldWidget.formData || formBorderConfig != oldWidget.formBorderConfig;
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

  /// 表单边框配置（作用于本 builder 子树内的所有表单边框）
  ///
  /// 按引用捕获：运行期修改请替换实例（`formBorderConfig = newCfg`，
  /// 通常用 `copyWith` 生成），原地修改同一实例不会触发子树重建。
  final WFormBorderConfig? formBorderConfig;

  /// 创建表单构建器
  const WFormBuilder({
    super.key,
    required this.formData,
    required this.child,
    this.autovalidateMode,
    this.formBorderConfig,
  });

  /// 获取当前子树中的 [WFormData]（无祖先时返回 null）
  static WFormData? of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_WFormDataInherited>();
    return inherited?.formData;
  }

  /// 获取当前子树中的 [WFormData]，没有 [WFormBuilder] 祖先时抛 [StateError]
  static WFormData requireOf(BuildContext context) {
    final formData = of(context);
    if (formData == null) {
      throw StateError('WFormBuilder 未找到');
    }
    return formData;
  }

  /// 获取当前子树生效的边框配置
  ///
  /// 未配置时返回 null，此时 [WFormBorder] 不渲染任何装饰，
  /// 外观完全由显式配置决定。
  static WFormBorderConfig? borderConfigOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WFormDataInherited>()?.formBorderConfig;
  }

  @override
  Widget build(BuildContext context) {
    return _WFormDataInherited(
      formData: formData,
      formBorderConfig: formBorderConfig,
      child: FormBuilder(
        key: formData.formKey,
        autovalidateMode: autovalidateMode,
        child: child,
      ),
    );
  }
}
