import 'package:flutter/widgets.dart';

/// 表单只读作用域：向下传递「当前整块表单项是否只读」
///
/// `WFormBorderWithData` 始终插入该作用域，输入组件通过
/// [WFormReadOnlyScope.readOnlyOf] 读取，因此只读状态可以穿透任意包装
/// widget（Padding / Center / 自定义组件等），不再依赖逐个重建 widget 树。
class WFormReadOnlyScope extends InheritedWidget {
  /// 创建只读作用域
  const WFormReadOnlyScope({
    super.key,
    required this.readOnly,
    required super.child,
  });

  /// 当前作用域是否只读
  final bool readOnly;

  /// 读取最近的只读作用域（无作用域时返回 false）
  static bool readOnlyOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WFormReadOnlyScope>()?.readOnly ?? false;

  @override
  bool updateShouldNotify(WFormReadOnlyScope oldWidget) => readOnly != oldWidget.readOnly;
}
