import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_controller.dart';
import '../form_icons.dart';
import '../form_theme.dart';

/// 表单单选按钮组组件
///
/// 以单列布局渲染所有选项，支持自定义标题（[titleBuilder]）与选项下方
/// 附加内容（[itemExtraBuilder]）；选中状态、间距与图标可通过
/// `WFormRadioGroup` 的同名参数 配置，只读状态会合并外层 [WFormReadOnlyScope]。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormRadioGroupCore<T> extends FormBuilderField<T> {
  /// 未选中图标（null 时取 WFormTheme / WFormIcons 默认）
  final Widget? unselectedIcon;

  /// 选中图标
  final Widget? selectedIcon;

  /// 图标与标题间距
  final double? iconSpacing;

  /// 选项行距
  final double? lineSpacing;

  /// 图标纵向偏移
  final double? iconYOffset;

  /// 标题文字样式
  final TextStyle? style;

  /// 交互控件使用的焦点节点（由直接字段的 `focusNode` 传入）
  final FocusNode? interactionFocusNode;

  /// 外框高度
  final double? height;

  /// 外框宽度
  final double? width;

  /// 外框装饰（bordered 时由边框接管）
  final Decoration? containerDecoration;

  /// 外框外边距
  final EdgeInsetsGeometry? containerMargin;

  /// 选项内边距（作用在内层选项上）
  final EdgeInsetsGeometry? containerPadding;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 自定义标题构建器
  final Widget Function(BuildContext, T, String, bool)? titleBuilder;

  /// 自定义附加内容构建器（显示在每个选项下方）
  final Widget Function(BuildContext, T, String, bool)? itemExtraBuilder;

  /// 创建单选按钮组字段
  WFormRadioGroupCore({
    super.key,
    required super.name,
    required this.items,
    this.titleBuilder,
    this.itemExtraBuilder,
    super.initialValue,
    super.enabled = true,
    super.onChanged,
    super.validator,
    this.unselectedIcon,
    this.selectedIcon,
    this.iconSpacing,
    this.lineSpacing,
    this.iconYOffset,
    this.style,
    this.height,
    this.width,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
    this.leading,
    this.actions,
    this.interactionFocusNode,
  }) : super(
         builder: (FormFieldState<T?> field) {
           final state = field as _WFormRadioGroupState<T>;
           final theme = WFormThemeData.of(field.context);

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnly.of(field.context);

           void click(T v) {
             if (!isEnabled) {
               return;
             }
             state.didChange(v);
           }

           final options = Padding(
             padding: containerPadding ?? EdgeInsets.zero,
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               spacing: lineSpacing ?? 0,
               children: items.entries.map((element) {
                 final isSelected = state.value == element.key;
                 // 外部 focusNode 只绑到第一个选项：同一个 FocusNode 不能同时挂到
                 // 多个 FocusableActionDetector 上；其余选项各自持有内部节点。
                 final isFirstOption = element.key == items.keys.first;

                 Widget? child = itemExtraBuilder != null
                     ? itemExtraBuilder(field.context, element.key, element.value, isSelected)
                     : null;

                 return FocusableActionDetector(
                   enabled: isEnabled,
                   focusNode: isFirstOption ? state.interactionFocusNode : null,
                   actions: <Type, Action<Intent>>{
                     ActivateIntent: CallbackAction<ActivateIntent>(
                       onInvoke: (_) {
                         click(element.key);
                         return null;
                       },
                     ),
                   },
                   child: Semantics(
                     container: true,
                     checked: isSelected,
                     inMutuallyExclusiveGroup: true,
                     enabled: isEnabled,
                     onTap: isEnabled ? () => click(element.key) : null,
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Row(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             MouseRegion(
                               cursor: isEnabled
                                   ? SystemMouseCursors.click
                                   : SystemMouseCursors.basic,
                               child: GestureDetector(
                                 behavior: HitTestBehavior.opaque,
                                 excludeFromSemantics: true,
                                 onTap: () => click(element.key),
                                 child: Transform(
                                   transform: Matrix4.translationValues(
                                     0,
                                     iconYOffset ?? 0,
                                     0,
                                   ),
                                   child: isSelected
                                       ? selectedIcon ??
                                             theme?.effectiveRadioSelectedIcon ??
                                             WFormIcons.defaults.radioSelected
                                       : unselectedIcon ??
                                             theme?.effectiveRadioUnselectedIcon ??
                                             WFormIcons.defaults.radioUnselected,
                                 ),
                               ),
                             ),
                             SizedBox(width: iconSpacing ?? 0),
                             Expanded(
                               child: MouseRegion(
                                 cursor: isEnabled
                                     ? SystemMouseCursors.click
                                     : SystemMouseCursors.basic,
                                 child: GestureDetector(
                                   behavior: HitTestBehavior.opaque,
                                   excludeFromSemantics: true,
                                   onTap: () => click(element.key),
                                   child: titleBuilder != null
                                       ? titleBuilder(
                                           field.context,
                                           element.key,
                                           element.value,
                                           isSelected,
                                         )
                                       : Text(
                                           element.value,
                                           style: style,
                                           strutStyle: StrutStyle(
                                             fontFamily: style?.fontFamily,
                                             fontSize: style?.fontSize,
                                             fontWeight: style?.fontWeight,
                                             height: style?.height,
                                             forceStrutHeight: true,
                                           ),
                                         ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                         if (child != null) child,
                       ],
                     ),
                   ),
                 );
               }).toList(),
             ),
           );

           return WFormFieldFrame(
             height: height,
             width: width,
             decoration: containerDecoration,
             margin: containerMargin,
             // containerPadding 作用在内层选项 Padding 上，外框不再重复施加
             padding: null,
             leading: leading,
             actions: actions,
             child: Opacity(opacity: isEnabled ? 1 : 0.5, child: options),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormRadioGroupCore<T>, T> createState() => _WFormRadioGroupState<T>();
}

/// WFormRadioGroupCore 的状态类
class _WFormRadioGroupState<T> extends FormBuilderFieldState<WFormRadioGroupCore<T>, T> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  /// 未传 external focusNode 时自建的交互节点
  FocusNode? _ownFocusNode;

  /// 交互控件实际使用的焦点节点
  FocusNode get interactionFocusNode =>
      widget.interactionFocusNode ?? (_ownFocusNode ??= FocusNode(debugLabel: widget.name));

  @override
  void focus() => interactionFocusNode.requestFocus();

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormController.of(context);
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.clearError(widget.name);
  }
}
