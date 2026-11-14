import 'package:flutter/widgets.dart';

/// 读取表单只读状态（公开入口）。
///
/// 只读作用域由 `WForm` / `WFormFieldShell` 自动插入，业务不需要构造。
abstract final class WFormReadOnly {
  /// 当前子树是否只读（无只读作用域时返回 false）
  static bool of(BuildContext context) => WFormReadOnlyScope.readOnlyOf(context);
}

/// 表单只读作用域（包内实现）：向下传递「当前整块表单项是否只读」。
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
