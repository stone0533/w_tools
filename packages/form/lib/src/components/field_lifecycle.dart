import 'package:flutter/widgets.dart';

import 'form_controller.dart';
import 'form_scope.dart';

/// 无状态表单字段的生命周期清理包装。
///
/// WFormDropdownCore / WFormMultiDropdownCore 自身是 StatelessWidget，无法在 dispose
/// 时清理 formEntered；本组件只负责在字段卸载 / name 变化时注销输入状态。
class WFormFieldCleanup extends StatefulWidget {
  const WFormFieldCleanup({
    super.key,
    required this.name,
    required this.child,
  });

  final String name;
  final Widget child;

  @override
  State<WFormFieldCleanup> createState() => _WFormFieldCleanupState();
}

class _WFormFieldCleanupState extends State<WFormFieldCleanup> {
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = WFormScope.of(context);
    if (!identical(_formData, next)) {
      _formData?.removeFormEntered(widget.name);
      _formData = next;
    }
  }

  @override
  void didUpdateWidget(WFormFieldCleanup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _formData?.removeFormEntered(oldWidget.name);
    }
  }

  @override
  void dispose() {
    _formData?.removeFormEntered(widget.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
