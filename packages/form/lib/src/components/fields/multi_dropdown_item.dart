part of 'multi_dropdown.dart';

enum _WFormMultiDropdownItemStatus {
  /// 启用状态
  enable,

  /// 选中状态
  checked,

  /// 禁用状态
  disable,
}

/// 多选下拉框选项点击回调
typedef _WFormMultiDropdownItemTapCallback<T> = void Function(T value, bool isChecked);

/// 多选下拉框选项组件
class _WFormMultiDropdownItem<T> extends StatefulWidget {
  /// 选项值
  final T value;

  /// 选项标题
  final String title;

  /// 标题内边距
  final EdgeInsetsGeometry? titlePadding;

  /// 选项状态
  final _WFormMultiDropdownItemStatus status;

  /// 是否禁用（与 [status] 分离：已禁用的项若已选中，仍显示选中态但不可点击）
  final bool disabled;

  /// 点击回调
  final _WFormMultiDropdownItemTapCallback<T> onTap;

  /// 文本样式
  final TextStyle? style;

  /// 选中状态文本样式
  final TextStyle? checkedStyle;

  /// 禁用状态文本样式
  final TextStyle? disabledStyle;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 未选中状态图标
  final Widget icon;

  /// 选中状态图标
  final Widget checkedIcon;

  /// 禁用状态图标
  final Widget? disabledIcon;

  /// 创建选项组件
  const _WFormMultiDropdownItem({
    required this.value,
    required this.title,
    this.titlePadding,
    this.status = _WFormMultiDropdownItemStatus.enable,
    this.disabled = false,
    required this.onTap,
    this.padding,
    this.style,
    this.checkedStyle,
    this.disabledStyle,
    required this.icon,
    required this.checkedIcon,
    this.disabledIcon,
  });

  @override
  State<_WFormMultiDropdownItem<T>> createState() => _WFormMultiDropdownItemState<T>();
}

/// _WFormMultiDropdownItem 的状态类
class _WFormMultiDropdownItemState<T> extends State<_WFormMultiDropdownItem<T>> {
  /// 是否选中
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.status == _WFormMultiDropdownItemStatus.checked;
  }

  @override
  void didUpdateWidget(covariant _WFormMultiDropdownItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部值变化（回填 / 重置）后，让本地选中态重新跟随 status
    if (widget.status != oldWidget.status) {
      isChecked = widget.status == _WFormMultiDropdownItemStatus.checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.status == _WFormMultiDropdownItemStatus.disable;

    void toggle() {
      if (isDisabled) return;
      setState(() {
        isChecked = !isChecked;
      });
      widget.onTap.call(widget.value, isChecked);
    }

    return Semantics(
      container: true,
      button: true,
      checked: isChecked,
      enabled: !isDisabled,
      onTap: isDisabled ? null : toggle,
      child: FocusableActionDetector(
        enabled: !isDisabled,
        mouseCursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: toggle,
          excludeFromSemantics: true,
          child: Container(
            padding: widget.padding ?? EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.status == _WFormMultiDropdownItemStatus.disable
                    ? widget.disabledIcon ?? widget.icon
                    : isChecked
                    ? widget.checkedIcon
                    : widget.icon,
                Padding(
                  padding: widget.titlePadding ?? const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.title,
                    style: widget.status == _WFormMultiDropdownItemStatus.disable
                        ? widget.disabledStyle ?? widget.style
                        : isChecked
                        ? widget.checkedStyle ?? widget.style
                        : widget.style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 多选下拉框配置类，定义多选下拉框的样式和行为
