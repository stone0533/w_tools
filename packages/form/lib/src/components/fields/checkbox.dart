import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../border/border_with_data.dart';
import '../border/read_only_scope.dart';
import '../form_builder.dart';
import '../form_data.dart';
import '../form_defaults.dart';

/// 单个复选框字段组件
///
/// 点击图标或标题切换选中状态；选中 / 未选中 / 禁用图标、间距与图标偏移可通过
/// [WFormCheckboxConfig] 配置，未配置时取 [WFormDefaults] 的默认图标。
class WFormCheckbox extends FormBuilderField<bool> {
  /// 复选框配置
  final WFormCheckboxConfig config;

  /// 标题 widget（会占满剩余宽度，适合整行布局）
  final Widget? title;

  /// 创建复选框字段
  WFormCheckbox({
    super.key,
    required this.config,
    required super.name,
    required this.title,
    bool super.initialValue = false,
    bool? enabled,
    super.onChanged,
    super.validator,
  }) : super(
         enabled: enabled ?? config._enabled,
         builder: (FormFieldState<bool?> field) {
           final state = field as FormBuilderFieldState<WFormCheckbox, bool>;

           // 继承外层只读作用域（WFormBorderWithData.readOnly）
           final isEnabled = state.enabled && !WFormReadOnlyScope.readOnlyOf(field.context);

           void toggle() {
             if (!isEnabled) {
               return;
             }
             final nextValue = !(state.value ?? false);
             state.didChange(nextValue);
           }

           Widget buildIcon() {
             if (!isEnabled && config._disabledIcon != null) {
               return config._disabledIcon!;
             }
             if (state.value == true) {
               return config._selectedIcon ?? WFormDefaults.checkboxSelectedIcon;
             }
             return config._unselectedIcon ?? WFormDefaults.checkboxUnselectedIcon;
           }

           return Semantics(
             container: true,
             checked: state.value == true,
             enabled: isEnabled,
             child: Container(
               height: config._height,
               width: config._width,
               alignment: Alignment.center,
               decoration: config._containerDecoration,
               margin: config._containerMargin,
               padding: config._containerPadding,
               child: Row(
                 children: [
                   config._leading ?? const SizedBox.shrink(),
                   Expanded(
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         MouseRegion(
                           cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                           child: GestureDetector(
                             behavior: HitTestBehavior.opaque,
                             onTap: toggle,
                             child: Transform(
                               transform: Matrix4.translationValues(
                                 0,
                                 config._iconYOffset ?? 0,
                                 0,
                               ),
                               child: buildIcon(),
                             ),
                           ),
                         ),
                         SizedBox(width: config._iconSpacing ?? 0),
                         Expanded(
                           child: MouseRegion(
                             cursor: isEnabled
                                 ? SystemMouseCursors.click
                                 : SystemMouseCursors.basic,
                             child: GestureDetector(
                               behavior: HitTestBehavior.opaque,
                               onTap: toggle,
                               child: title,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                   ...?config._actions,
                 ],
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<WFormCheckbox, bool> createState() => _WFormCheckboxState();
}

/// WFormCheckbox 的状态类
class _WFormCheckboxState extends FormBuilderFieldState<WFormCheckbox, bool> {
  /// 宿主表单数据（在 [didChangeDependencies] 中获取）
  WFormData? _formData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formData = WFormBuilder.of(context);
  }

  @override
  void didChange(bool? value) {
    super.didChange(value);
    // 交互与表单 reset 都会经过 didChange，统一在此维护输入状态
    _formData?.onChange(widget.name, value);
  }
}

/// 复选框配置类，定义复选框的样式和行为
class WFormCheckboxConfig {
  /// 未选中状态的图标
  Widget? _unselectedIcon;

  /// 选中状态的图标
  Widget? _selectedIcon;

  /// 禁用状态的图标
  Widget? _disabledIcon;

  /// 图标与标题之间的间距
  double? _iconSpacing;

  /// 图标 Y 轴偏移
  double? _iconYOffset;

  /// 是否启用
  bool _enabled = true;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// 左侧组件
  Widget? _leading;

  /// 操作按钮列表
  List<Widget>? _actions;

  /// 容器装饰
  Decoration? _containerDecoration;

  /// 容器边距
  EdgeInsetsGeometry? _containerMargin;

  /// 容器内边距
  EdgeInsetsGeometry? _containerPadding;

  /// 设置禁用状态图标（null 表示使用默认）
  set disabledIcon(Widget? value) {
    _disabledIcon = value;
  }

  /// 设置未选中状态图标（null 表示使用默认图标）
  set unselectedIcon(Widget? value) {
    _unselectedIcon = value;
  }

  /// 设置选中状态图标（null 表示使用默认图标）
  set selectedIcon(Widget? value) {
    _selectedIcon = value;
  }

  /// 设置图标与标题之间的间距（null 表示无额外间距）
  set iconSpacing(double? value) {
    _iconSpacing = value;
  }

  /// 设置图标 Y 轴偏移（null 表示不偏移）
  set iconYOffset(double? value) {
    _iconYOffset = value;
  }

  /// 设置是否启用
  set enabled(bool value) {
    _enabled = value;
  }

  /// 设置高度
  set height(double? value) {
    _height = value;
  }

  /// 设置宽度
  set width(double? value) {
    _width = value;
  }

  /// 设置左侧组件
  set leading(Widget? value) {
    _leading = value;
  }

  /// 设置操作按钮列表
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 设置容器装饰
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 设置容器边距
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 设置容器内边距
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
  }

  /// 构建 [WFormCheckbox] 组件
  ///
  /// [enabled] 为 null 时使用配置中的值。
  WFormCheckbox build({
    required String name,
    required Widget title,
    bool initialValue = false,
    bool? enabled,
    ValueChanged<bool?>? onChanged,
    FormFieldValidator<bool>? validator,
  }) {
    return WFormCheckbox(
      config: this,
      name: name,
      title: title,
      initialValue: initialValue,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// 构建带有 [WFormBorderWithData] 包装的 [WFormCheckbox] 组件
  ///
  /// 内层容器装饰会被清空，边框交由外层绘制。
  /// [readOnly] 为 true 时内层不可交互、外层使用只读装饰。
  Widget buildBordered({
    required String name,
    required Widget title,
    bool initialValue = false,
    bool? enabled,
    ValueChanged<bool?>? onChanged,
    FormFieldValidator<bool>? validator,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
    bool readOnly = false,
  }) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '字段名称不能为空');
    }

    final baseEnabled = enabled ?? _enabled;
    final innerConfig = copy()..containerDecoration = null;

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: readOnly || !baseEnabled,
      enableFocusBorder: enableFocusBorder,
      child: innerConfig.build(
        name: name,
        title: title,
        initialValue: initialValue,
        enabled: baseEnabled && !readOnly,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  /// 创建当前配置的副本
  WFormCheckboxConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// 参数为 null 表示沿用原值。
  WFormCheckboxConfig copyWith({
    Widget? unselectedIcon,
    Widget? selectedIcon,
    Widget? disabledIcon,
    double? iconSpacing,
    double? iconYOffset,
    bool? enabled,
    double? height,
    double? width,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    final config = WFormCheckboxConfig();
    config._unselectedIcon = unselectedIcon ?? _unselectedIcon;
    config._selectedIcon = selectedIcon ?? _selectedIcon;
    config._disabledIcon = disabledIcon ?? _disabledIcon;
    config._iconSpacing = iconSpacing ?? _iconSpacing;
    config._iconYOffset = iconYOffset ?? _iconYOffset;
    config._enabled = enabled ?? _enabled;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    return config;
  }
}
