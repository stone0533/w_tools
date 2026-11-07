import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'border/border.dart';
import 'form_controller.dart';

/// 表单数据继承组件，用于在 widget 树中传递 WFormController 与表单边框配置
class _WFormControllerInherited extends InheritedWidget {
  /// 表单数据对象
  final WFormController formData;

  /// 表单边框配置
  final WFormBorderConfig? formBorderConfig;

  const _WFormControllerInherited({
    required this.formData,
    required this.formBorderConfig,
    required super.child,
  });

  @override
  bool updateShouldNotify(_WFormControllerInherited oldWidget) {
    return formData != oldWidget.formData || formBorderConfig != oldWidget.formBorderConfig;
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

  /// 表单边框配置（作用于本 builder 子树内的所有表单边框）
  ///
  /// 按引用捕获：运行期修改请替换实例（`formBorderConfig = newCfg`，
  /// 通常用 `copyWith` 生成），原地修改同一实例不会触发子树重建。
  final WFormBorderConfig? formBorderConfig;

  /// 创建表单构建器
  const WFormScope({
    super.key,
    required this.formData,
    required this.child,
    this.autovalidateMode,
    this.formBorderConfig,
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
  /// 未配置时返回 null，此时 [WFormBorder] 不渲染任何装饰，
  /// 外观完全由显式配置决定。
  static WFormBorderConfig? borderConfigOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_WFormControllerInherited>()
        ?.formBorderConfig;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderConfig = formBorderConfig ?? WFormBorderConfigScope.maybeOf(context);
    return WFormBorderConfigScope(
      config: effectiveBorderConfig,
      child: _WFormControllerInherited(
        formData: formData,
        formBorderConfig: effectiveBorderConfig,
        child: FormBuilder(
          key: formData.formKey,
          autovalidateMode: autovalidateMode,
          onChanged: onChanged == null ? null : () => onChanged!(formData.value),
          child: child,
        ),
      ),
    );
  }
}
