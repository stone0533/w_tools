import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'form_controller.dart';

/// 表单构建器组件（包内实现，不导出）。
///
/// 业务页面用 `WForm`；需要 controller 时用 `WFormController.of(context)`。
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
  static WFormController? of(BuildContext context) => WFormController.of(context);

  /// 获取当前子树中的 [WFormController]，没有祖先时抛 [StateError]
  static WFormController requireOf(BuildContext context) => WFormController.requireOf(context);

  @override
  Widget build(BuildContext context) {
    return WFormControllerScope(
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
