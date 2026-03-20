import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../utils/popup.dart';

/// 表单多选下拉框组件
class WFormMultiDropdown<T> extends StatelessWidget {
  /// 多选下拉框配置
  final WFormMultiDropdownConfig config;

  /// 字段名称
  final String name;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 初始值
  final T? initialValue;

  /// 值变化回调
  final ValueChanged<T?>? onChanged;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 多选下拉框配置
  /// @param name 字段名称
  /// @param items 选项映射
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  const WFormMultiDropdown({
    super.key,
    required this.config,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: config._height,
      width: config._width,
      alignment: Alignment.center,
      decoration: config._containerDecoration,
      margin: config._containerMargin,
      padding: config._containerPadding,
      child: Row(
        children: [
          config._leading ?? Container(),
          Expanded(
            child: Container(
              transform: config._yOffset != null
                  ? Matrix4.translationValues(0, config._yOffset!, 0)
                  : null,
              child: _FormBuilderMultiDropdown<T>(
                name: name,
                items: items,
                initialValue: initialValue,
                onChanged: onChanged,
                enabled: config._enabled,
                decoration: config._decoration,
                icon: config._icon,
                iconSize: config._iconSize,
                iconDisabledColor: config._iconDisabledColor,
                iconEnabledColor: config._iconEnabledColor,
                checkBoxIcon: config._unselectedIcon,
                checkBoxCheckedIcon: config._selectedIcon,
                checkBoxDisabledIcon: config._disabledIcon,
                style: config._style,
                popUpLayerPadding: config._popUpLayerPadding,
                popUpLayerTitleStyle: config._popUpLayerTitleStyle,
                popUpLayerTitlePadding: config._popUpLayerTitlePadding,
                popUpLayerElevation: config._popUpLayerElevation,
                popUpLayerShadowColor: config._popUpLayerShadowColor,
                disabledKeys: config._disabledKeys,
              ),
            ),
          ),
          ...?config._actions?.map(
            (action) => Container(
              height: config._height,
              alignment: Alignment.center,
              child: action,
            ),
          ),
        ],
      ),
    );
  }
}

/// 内部多选下拉框组件
class _FormBuilderMultiDropdown<T> extends FormBuilderField<T> {
  /// 图标大小
  final double iconSize;

  /// 下拉按钮图标的 widget
  ///
  /// 默认是带有 [Icons.arrow_drop_down] 图标的 [Icon]。
  final Widget? icon;

  /// 当按钮禁用时，[icon] 的任何 [Icon] 后代的颜色
  ///
  /// 当主题的 [ThemeData.brightness] 为 [Brightness.light] 时默认为 [Colors.grey.shade400]，
  /// 当为 [Brightness.dark] 时默认为 [Colors.white10]
  final Color? iconDisabledColor;

  /// 当按钮启用时，[icon] 的任何 [Icon] 后代的颜色
  ///
  /// 当主题的 [ThemeData.brightness] 为 [Brightness.light] 时默认为 [Colors.grey.shade700]，
  /// 当为 [Brightness.dark] 时默认为 [Colors.white70]
  final Color? iconEnabledColor;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 未选中状态的复选框图标
  final Widget? checkBoxIcon;

  /// 选中状态的复选框图标
  final Widget? checkBoxCheckedIcon;

  /// 禁用状态的复选框图标
  final Widget? checkBoxDisabledIcon;

  /// 文本样式
  final TextStyle? style;

  /// 输入装饰
  final InputDecoration? decoration;

  /// 弹出层内边距
  final EdgeInsets? popUpLayerPadding;

  /// 弹出层标题样式
  final TextStyle? popUpLayerTitleStyle;

  /// 弹出层标题内边距
  final EdgeInsets? popUpLayerTitlePadding;

  /// 弹出层阴影高度
  final double? popUpLayerElevation;

  /// 弹出层阴影颜色
  final Color? popUpLayerShadowColor;

  /// 禁用的键，逗号分隔
  final String? disabledKeys;

  /// 构造函数
  ///
  /// @param name 字段名称
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param enabled 是否启用
  /// @param decoration 输入装饰
  /// @param icon 下拉按钮图标
  /// @param iconSize 图标大小
  /// @param iconDisabledColor 禁用状态图标颜色
  /// @param iconEnabledColor 启用状态图标颜色
  /// @param items 选项映射
  /// @param checkBoxIcon 未选中状态的复选框图标
  /// @param checkBoxCheckedIcon 选中状态的复选框图标
  /// @param checkBoxDisabledIcon 禁用状态的复选框图标
  /// @param style 文本样式
  /// @param popUpLayerPadding 弹出层内边距
  /// @param popUpLayerTitleStyle 弹出层标题样式
  /// @param popUpLayerTitlePadding 弹出层标题内边距
  /// @param popUpLayerElevation 弹出层阴影高度
  /// @param popUpLayerShadowColor 弹出层阴影颜色
  /// @param disabledKeys 禁用的键，逗号分隔
  _FormBuilderMultiDropdown({
    super.key,
    required super.name,
    super.initialValue,
    super.onChanged,
    super.enabled,
    this.decoration,
    this.icon,
    this.iconSize = 24,
    this.iconDisabledColor,
    this.iconEnabledColor,
    required this.items,
    this.checkBoxIcon,
    this.checkBoxCheckedIcon,
    this.checkBoxDisabledIcon,
    this.style,
    this.popUpLayerPadding,
    this.popUpLayerTitleStyle,
    this.popUpLayerTitlePadding,
    this.popUpLayerElevation,
    this.popUpLayerShadowColor,
    this.disabledKeys,
  }) : super(
         builder: (FormFieldState<T?> field) {
           final state = field as _FormBuilderMultiDropdownState<T>;

           // 格式化显示文本
           String title = '';
           List<String> stateList = state.value != null ? state.value.toString().split(',') : [];
           if (stateList.isNotEmpty) {
             items.forEach((key, value) {
               if (stateList.contains(key.toString())) {
                 if (title.isNotEmpty) {
                   title = '$title, ';
                 }
                 title = title + value;
               }
             });
           }

           // 如果没有选中任何项，显示 'ALL'
           if (title.isEmpty) {
             title = 'ALL';
           }

           return InputDecorator(
             decoration: decoration ?? const InputDecoration(
               border: InputBorder.none,
               focusedBorder: InputBorder.none,
               enabledBorder: InputBorder.none,
             ),
             child: GestureDetector(
               onTap: enabled ? () {
                 // 显示弹出层
                 showPopup(
                   context: state.context,
                   elevation: popUpLayerElevation ?? 10,
                   shadowColor: popUpLayerShadowColor ?? Colors.grey,
                   builder: (context) {
                     return Container(
                       width: double.infinity,
                       padding: popUpLayerPadding,
                       child: SingleChildScrollView(
                         child: Wrap(
                           children: items.entries.map((e) {
                             // 确定选项状态
                             _FormBuilderMultiDropdownItemStatue statue =
                                 _FormBuilderMultiDropdownItemStatue.enable;

                             // 检查是否选中
                             if (state.value != null) {
                               if (',${state.value},'.contains(',${e.key},')) {
                                 statue = _FormBuilderMultiDropdownItemStatue.checked;
                               }
                             }

                             // 检查是否禁用
                             if (disabledKeys?.isNotEmpty ?? false) {
                               if (',$disabledKeys,'.contains(',${e.key},')) {
                                 statue = _FormBuilderMultiDropdownItemStatue.disable;
                               }
                             }

                             // 创建选项项
                             return _FormBuilderMultiDropdownItem(
                               value: e.key.toString(),
                               title: e.value,
                               icon: checkBoxIcon ?? const Icon(Icons.check_box_outline_blank),
                               checkedIcon:
                                   checkBoxCheckedIcon ?? const Icon(Icons.check_box_outlined),
                               disabledIcon: checkBoxDisabledIcon,
                               statue: statue,
                               onTap: (v, isChecked) {
                                 List<String> list = state.value != null
                                     ? state.value.toString().split(',')
                                     : [];
                                 if (isChecked) {
                                   if (list.contains(v) == false) {
                                     list.add(v);
                                   }
                                 } else {
                                   if (list.contains(v)) {
                                     list.remove(v);
                                   }
                                 }

                                 // 更新值
                                 T? newValue = list.isNotEmpty ? list.join(',') as T? : null;
                                 state.setValue(newValue);
                                 state.didChange(newValue);
                               },
                               titlePadding: popUpLayerTitlePadding,
                               style: popUpLayerTitleStyle,
                             );
                           }).toList(),
                         ),
                       ),
                     );
                   },
                 );
               } : null,
               behavior: HitTestBehavior.translucent,
               child: Row(
                 children: [
                   Expanded(
                     child: Text(
                       title,
                       style: style,
                       strutStyle: style != null
                           ? StrutStyle(
                               fontFamily: style.fontFamily,
                               fontWeight: style.fontWeight,
                               fontSize: style.fontSize,
                               leading: 0,
                               forceStrutHeight: true,
                               height: 1.3,
                             )
                           : null,
                     ),
                   ),
                   icon ??
                       Icon(
                         Icons.arrow_drop_down,
                         size: iconSize,
                         color: enabled ? iconEnabledColor : iconDisabledColor,
                       ),
                 ],
               ),
             ),
           );
         },
       );

  @override
  FormBuilderFieldState<_FormBuilderMultiDropdown<T>, T> createState() =>
      _FormBuilderMultiDropdownState<T>();
}

/// _FormBuilderMultiDropdown 的状态类
class _FormBuilderMultiDropdownState<T>
    extends FormBuilderFieldState<_FormBuilderMultiDropdown<T>, T> {}

/// 多选下拉框选项状态枚举
enum _FormBuilderMultiDropdownItemStatue {
  /// 启用状态
  enable,

  /// 选中状态
  checked,

  /// 禁用状态
  disable,
}

/// 多选下拉框选项点击回调
typedef _FormBuilderMultiDropdownItemGestureTapCallback =
    void Function(String value, bool isChecked);

/// 多选下拉框选项组件
class _FormBuilderMultiDropdownItem extends StatefulWidget {
  /// 选项值
  final String value;

  /// 选项标题
  final String title;

  /// 标题内边距
  final EdgeInsetsGeometry? titlePadding;

  /// 选项状态
  final _FormBuilderMultiDropdownItemStatue statue;

  /// 点击回调
  final _FormBuilderMultiDropdownItemGestureTapCallback onTap;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 文本样式
  final TextStyle? style;

  /// 选中状态文本样式
  final TextStyle? checkedStyle;

  /// 禁用状态文本样式
  final TextStyle? disabledStyle;

  /// 未选中状态图标
  final Widget icon;

  /// 选中状态图标
  final Widget checkedIcon;

  /// 禁用状态图标
  final Widget? disabledIcon;

  /// 构造函数
  ///
  /// @param value 选项值
  /// @param title 选项标题
  /// @param titlePadding 标题内边距
  /// @param statue 选项状态
  /// @param onTap 点击回调
  /// @param padding 内边距
  /// @param style 文本样式
  /// @param checkedStyle 选中状态文本样式
  /// @param disabledStyle 禁用状态文本样式
  /// @param icon 未选中状态图标
  /// @param checkedIcon 选中状态图标
  /// @param disabledIcon 禁用状态图标
  const _FormBuilderMultiDropdownItem({
    required this.value,
    required this.title,
    this.titlePadding,
    this.statue = _FormBuilderMultiDropdownItemStatue.enable,
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
  State<_FormBuilderMultiDropdownItem> createState() => _FormBuilderMultiDropdownItemState();
}

/// _FormBuilderMultiDropdownItem 的状态类
class _FormBuilderMultiDropdownItemState extends State<_FormBuilderMultiDropdownItem> {
  /// 是否选中
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.statue == _FormBuilderMultiDropdownItemStatue.checked;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.statue == _FormBuilderMultiDropdownItemStatue.disable) {
          return;
        }
        setState(() {
          isChecked = !isChecked;
        });
        widget.onTap.call(widget.value, isChecked);
      },
      child: Container(
        padding: widget.padding ?? EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 根据状态显示不同图标
            widget.statue == _FormBuilderMultiDropdownItemStatue.disable
                ? widget.disabledIcon ?? widget.icon
                : isChecked
                ? widget.checkedIcon
                : widget.icon,
            Padding(
              padding: widget.titlePadding ?? const EdgeInsets.only(left: 8),
              child: Text(
                widget.title,
                style: widget.statue == _FormBuilderMultiDropdownItemStatue.disable
                    ? widget.disabledStyle ?? widget.style
                    : isChecked
                    ? widget.checkedStyle ?? widget.style
                    : widget.style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 多选下拉框配置类，定义多选下拉框的样式和行为
class WFormMultiDropdownConfig {
  /// 是否启用
  bool _enabled = true;

  /// 高度
  double? _height;

  /// 宽度
  double? _width;

  /// 内容内边距
  EdgeInsetsGeometry? _contentPadding;

  /// Y轴偏移
  double? _yOffset;

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

  /// 输入装饰
  InputDecoration? _decoration;

  /// 图标大小
  double _iconSize = 24;

  /// 下拉按钮图标
  Widget? _icon;

  /// 禁用状态图标颜色
  Color? _iconDisabledColor;

  /// 启用状态图标颜色
  Color? _iconEnabledColor;

  /// 未选中状态的复选框图标
  Widget? _unselectedIcon;

  /// 选中状态的复选框图标
  Widget? _selectedIcon;

  /// 禁用状态的复选框图标
  Widget? _disabledIcon;

  /// 文本样式
  TextStyle? _style;

  /// 弹出层内边距
  EdgeInsets? _popUpLayerPadding;

  /// 弹出层标题样式
  TextStyle? _popUpLayerTitleStyle;

  /// 弹出层标题内边距
  EdgeInsets? _popUpLayerTitlePadding;

  /// 弹出层阴影高度
  double? _popUpLayerElevation;

  /// 弹出层阴影颜色
  Color? _popUpLayerShadowColor;

  /// 禁用的键，逗号分隔
  String? _disabledKeys;

  /// 是否启用 setter
  set enabled(bool value) {
    _enabled = value;
  }

  /// 高度 setter
  set height(double? value) {
    _height = value;
  }

  /// 宽度 setter
  set width(double? value) {
    _width = value;
  }

  /// 内容内边距 setter
  set contentPadding(EdgeInsetsGeometry? value) {
    _contentPadding = value;
  }

  /// Y轴偏移 setter
  set yOffset(double? value) {
    _yOffset = value;
  }

  /// 左侧组件 setter
  set leading(Widget? value) {
    _leading = value;
  }

  /// 操作按钮列表 setter
  set actions(List<Widget>? value) {
    _actions = value;
  }

  /// 容器装饰 setter
  set containerDecoration(Decoration? value) {
    _containerDecoration = value;
  }

  /// 容器边距 setter
  set containerMargin(EdgeInsetsGeometry? value) {
    _containerMargin = value;
  }

  /// 容器内边距 setter
  set containerPadding(EdgeInsetsGeometry? value) {
    _containerPadding = value;
  }

  /// 输入装饰 setter
  set decoration(InputDecoration? value) {
    _decoration = value;
  }

  /// 图标大小 setter
  set iconSize(double value) {
    _iconSize = value;
  }

  /// 下拉按钮图标 setter
  set icon(Widget? value) {
    _icon = value;
  }

  /// 禁用状态图标颜色 setter
  set iconDisabledColor(Color? value) {
    _iconDisabledColor = value;
  }

  /// 启用状态图标颜色 setter
  set iconEnabledColor(Color? value) {
    _iconEnabledColor = value;
  }

  /// 未选中状态的复选框图标 setter
  set unselectedIcon(Widget? value) {
    _unselectedIcon = value;
  }

  /// 选中状态的复选框图标 setter
  set selectedIcon(Widget? value) {
    _selectedIcon = value;
  }

  /// 禁用状态的复选框图标 setter
  set disabledIcon(Widget? value) {
    _disabledIcon = value;
  }

  /// 文本样式 setter
  set style(TextStyle? value) {
    _style = value;
  }

  /// 弹出层内边距 setter
  set popUpLayerPadding(EdgeInsets? value) {
    _popUpLayerPadding = value;
  }

  /// 弹出层标题样式 setter
  set popUpLayerTitleStyle(TextStyle? value) {
    _popUpLayerTitleStyle = value;
  }

  /// 弹出层标题内边距 setter
  set popUpLayerTitlePadding(EdgeInsets? value) {
    _popUpLayerTitlePadding = value;
  }

  /// 弹出层阴影高度 setter
  set popUpLayerElevation(double? value) {
    _popUpLayerElevation = value;
  }

  /// 弹出层阴影颜色 setter
  set popUpLayerShadowColor(Color? value) {
    _popUpLayerShadowColor = value;
  }

  /// 禁用的键 setter
  set disabledKeys(String? value) {
    _disabledKeys = value;
  }

  /// 构建 WFormMultiDropdown 组件
  ///
  /// @param T 选项值类型
  /// @param name 字段名称
  /// @param items 选项映射，键为值，值为显示文本
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @return WFormMultiDropdown 实例
  WFormMultiDropdown<T> build<T>({
    required String name,
    required Map<T, String> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
  }) {
    return WFormMultiDropdown<T>(
      config: this,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}
