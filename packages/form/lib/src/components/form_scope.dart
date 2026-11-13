import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border.dart';
import 'form_controller.dart';
import 'form_theme.dart';

/// 表单数据继承组件，用于在 widget 树中传递 WFormController
class _WFormControllerInherited extends InheritedWidget {
  /// 表单数据对象
  final WFormController formData;

  const _WFormControllerInherited({
    required this.formData,
    required super.child,
  });

  @override
  bool updateShouldNotify(_WFormControllerInherited oldWidget) {
    return formData != oldWidget.formData;
  }
}

/// 表单构建器组件，用于创建和管理表单
class WFormScope extends StatelessWidget {
  /// 表单数据对象
  final WFormController formData;

  /// 子组件
  final Widget child;

  /// 自动验证模式
  final AutovalidateMode? autovalidateMode;

  /// 任一字段值变化后的回调（参数为当前整表值）
  final ValueChanged<Map<String, dynamic>>? onChanged;

  /// 创建表单构建器
  const WFormScope({
    super.key,
    required this.formData,
    required this.child,
    this.autovalidateMode,
    this.onChanged,
  });

  /// 获取当前子树中的 [WFormController]（无祖先时返回 null）
  static WFormController? of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_WFormControllerInherited>();
    return inherited?.formData;
  }

  /// 获取当前子树中的 [WFormController]，没有 [WFormScope] 祖先时抛 [StateError]
  static WFormController requireOf(BuildContext context) {
    final formData = of(context);
    if (formData == null) {
      throw StateError('WFormScope 未找到');
    }
    return formData;
  }

  /// 获取当前子树生效的边框配置
  ///
  /// 读取最近 `WFormThemeData.borderStyle`；未配置时返回 null。
  static WFormBorderStyle? borderStyleOf(BuildContext context) =>
      WFormThemeData.of(context)?.borderStyle;

  @override
  Widget build(BuildContext context) {
    return _WFormControllerInherited(
      formData: formData,
      child: FormBuilder(
        key: formData.formKey,
        autovalidateMode: autovalidateMode,
        onChanged: onChanged == null ? null : () => onChanged!(formData.value),
        child: child,
      ),
    );
  }
}
