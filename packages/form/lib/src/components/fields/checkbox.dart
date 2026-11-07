import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/read_only_scope.dart';
import '../field_frame.dart';
import '../form_scope.dart';
import '../form_controller.dart';
import '../form_icons.dart';
import '../form_theme.dart';

/// 单个复选框字段组件
///
/// 点击图标或标题切换选中状态；选中 / 未选中 / 禁用图标、间距与图标偏移可通过
/// `WFormCheckbox` 的同名参数 配置，未配置时取 [WFormIcons.defaults] 的默认图标。
/// 框架内部使用：普通业务用直接字段（`WFormTextField` 等），4.0 移出公共面。
@internal
class WFormCheckboxCore extends FormBuilderField<bool> {
  /// 未选中图标（null 时取 WFormTheme / WFormIcons 默认）
  final Widget? unselectedIcon;

  /// 选中图标
  final Widget? selectedIcon;

  /// 禁用图标（null 时沿用选中/未选中图标）
  final Widget? disabledIcon;

  /// 图标与标题间距
  final double? iconSpacing;

  /// 图标纵向偏移
  final double? iconYOffset;

  /// 标题文字样式
  final TextStyle? style;

  /// 外框高度
  final double? height;

  /// 外框宽度
  final double? width;

  /// 外框装饰（bordered 时由边框接管）
  final Decoration? containerDecoration;

  /// 外框外边距
  final EdgeInsetsGeometry? containerMargin;

  /// 外框内边距
  final EdgeInsetsGeometry? containerPadding;

  /// 左侧插槽
  final Widget? leading;

  /// 右侧操作插槽
  final List<Widget>? actions;

  /// 标题 widget（会占满剩余宽度，适合整行布局）
  final Widget? title;

  /// 创建复选框字段
  WFormCheckboxCore({
    super.key,
    required super.name,
    required this.title,
    bool super.initialValue = false,
    super.enabled = true,
    super.onChanged,
    super.validator,
    this.unselectedIcon,
    this.selectedIcon,
    this.disabledIcon,
    this.iconSpacing,
    this.iconYOffset,
    this.style,
    this.height,
    this.width,
    this.containerDecoration,
    this.containerMargin,
    this.containerPadding,
    this.leading,
    this.actions,
    super.focusNode,
  }) : super(
         builder: (FormFieldState<bool?> field) {
           final state = field as FormBuilderFieldState<WFormCheckboxCore, bool>;
           final theme = WFormThemeData.of(field.context);

           // 继承外层只读作用域（WFormFieldShell.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(field.context);

           void toggle() {
             if (!isEnabled) {
               return;
             }
             final nextValue = !(state.value ?? false);
             state.didChange(nextValue);
           }

           Widget buildIcon() {
             if (!isEnabled && disabledIcon != null) {
               return disabledIcon;
             }
             if (state.value == true) {
               return selectedIcon ??
                   theme?.effectiveCheckboxSelectedIcon ??
                   WFormIcons.defaults.checkboxSelected;
             }
             return unselectedIcon ??
                 theme?.effectiveCheckboxUnselectedIcon ??
                 WFormIcons.defaults.checkboxUnselected;
           }

           return FocusableActionDetector(
             enabled: isEnabled,
             actions: <Type, Action<Intent>>{
               ActivateIntent: CallbackAction<ActivateIntent>(
                 onInvoke: (_) {
                   toggle();
                   return null;
                 },
               ),
             },
             child: Semantics(
               container: true,
               checked: state.value == true,
               enabled: isEnabled,
               onTap: isEnabled ? toggle : null,
               child: WFormFieldFrame(
                 height: height,
                 width: width,
                 decoration: containerDecoration,
                 margin: containerMargin,
                 padding: containerPadding,
                 leading: leading,
                 actions: actions,
                 child: Opacity(
                   opacity: isEnabled ? 1 : 0.5,
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       MouseRegion(
                         cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                         child: GestureDetector(
                           behavior: HitTestBehavior.opaque,
                           excludeFromSemantics: true,
                           onTap: toggle,
                           child: Transform(
                             transform: Matrix4.translationValues(0, iconYOffset ?? 0, 0),
                             child: buildIcon(),
                           ),
                         ),
                       ),
                       SizedBox(width: iconSpacing ?? 0),
                       Expanded(
                         child: MouseRegion(
                           cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                           child: GestureDetector(
                             behavior: HitTestBehavior.opaque,
                             excludeFromSemantics: true,
                             onTap: toggle,
                             child: DefaultTextStyle.merge(
                               style: style,
                               child: title ?? const SizedBox.shrink(),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormCheckboxCore, bool> createState() => _WFormCheckboxState();
}

/// WFormCheckboxCore 的状态类
class _WFormCheckboxState extends FormBuilderFieldState<WFormCheckboxCore, bool> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormController? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormScope.of(context);
  }

  @override
  void didChange(bool? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.handleChange(widget.name, value);
  }
}
