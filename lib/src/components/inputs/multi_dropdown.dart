import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../utils/popup.dart';
import 'border.dart';
import 'form_builder.dart';

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
    // 获取 WFormData 实例
    dynamic wFormData = WFormBuilder.of(context);

    if (wFormData == null) {
      // 尝试遍历祖先元素，查找 WFormBuilder 实例
      context.visitAncestorElements((element) {
        if (element.widget is WFormBuilder) {
          wFormData = (element.widget as WFormBuilder).formData;
          return false; // 停止遍历
        }
        return true; // 继续遍历
      });
    }

    if (wFormData == null) {
      throw Exception('WFormBuilder 未找到');
    }

    // 定义值变化回调函数
    void onChangedHandler(T? value) {
      // 确保 wFormData 不为 null
      if (wFormData != null) {
        wFormData.onChange(name, value);
      }
      // 调用用户传入的回调函数
      onChanged?.call(value);
    }

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
                onChanged: onChangedHandler,
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
                itemPadding: config._itemPadding,
                itemStyle: config._itemStyle,
                itemCheckedStyle: config._itemCheckedStyle,
                itemDisabledStyle: config._itemDisabledStyle,
                itemTitlePadding: config._itemTitlePadding,
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

  /// 选项项内边距
  final EdgeInsetsGeometry? itemPadding;

  /// 选项项标题样式
  final TextStyle? itemStyle;

  /// 选项项选中状态标题样式
  final TextStyle? itemCheckedStyle;

  /// 选项项禁用状态标题样式
  final TextStyle? itemDisabledStyle;

  /// 选项项标题内边距
  final EdgeInsets? itemTitlePadding;

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
  /// @param itemDisabledStyle 选项项禁用状态标题样式
  /// @param itemPadding 选项项内边距
  /// @param itemStyle 选项项标题样式
  /// @param itemCheckedStyle 选项项选中状态标题样式
  /// @param itemDisabledStyle 选项项禁用状态标题样式
  /// @param itemTitlePadding 选项项标题内边距
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
    this.itemPadding,
    this.itemStyle,
    this.itemCheckedStyle,
    this.itemDisabledStyle,
    this.itemTitlePadding,
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
             decoration:
                 decoration ??
                 const InputDecoration(
                   border: InputBorder.none,
                   focusedBorder: InputBorder.none,
                   enabledBorder: InputBorder.none,
                 ),
             child: GestureDetector(
               onTap: enabled
                   ? () {
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
                                     icon:
                                         checkBoxIcon ?? const Icon(Icons.check_box_outline_blank),
                                     checkedIcon:
                                         checkBoxCheckedIcon ??
                                         const Icon(Icons.check_box_outlined),
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
                                     titlePadding: itemTitlePadding,
                                     style: itemStyle,
                                     padding: itemPadding,
                                     checkedStyle: itemCheckedStyle,
                                     disabledStyle: itemDisabledStyle,
                                   );
                                 }).toList(),
                               ),
                             ),
                           );
                         },
                       );
                     }
                   : null,
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

  /// 选项项内边距
  EdgeInsetsGeometry? _itemPadding;

  /// 选项项标题样式
  TextStyle? _itemStyle;

  /// 选项项选中状态标题样式
  TextStyle? _itemCheckedStyle;

  /// 选项项禁用状态标题样式
  TextStyle? _itemDisabledStyle;

  /// 选项项标题内边距
  EdgeInsets? _itemTitlePadding;

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

  /// 选项项内边距 setter
  set itemPadding(EdgeInsetsGeometry? value) {
    _itemPadding = value;
  }

  /// 选项项标题样式 setter
  set itemStyle(TextStyle? value) {
    _itemStyle = value;
  }

  /// 选项项选中状态标题样式 setter
  set itemCheckedStyle(TextStyle? value) {
    _itemCheckedStyle = value;
  }

  /// 选项项禁用状态标题样式 setter
  set itemDisabledStyle(TextStyle? value) {
    _itemDisabledStyle = value;
  }

  /// 选项项标题内边距 setter
  set itemTitlePadding(EdgeInsets? value) {
    _itemTitlePadding = value;
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

  /// 创建当前配置的副本
  ///
  /// @return WFormMultiDropdownConfig 实例的副本
  WFormMultiDropdownConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param enabled 是否启用
  /// @param height 高度
  /// @param width 宽度
  /// @param contentPadding 内容内边距
  /// @param yOffset Y轴偏移
  /// @param leading 左侧组件
  /// @param actions 操作按钮列表
  /// @param containerDecoration 容器装饰
  /// @param containerMargin 容器边距
  /// @param containerPadding 容器内边距
  /// @param decoration 输入装饰
  /// @param iconSize 图标大小
  /// @param icon 下拉按钮图标
  /// @param iconDisabledColor 禁用状态图标颜色
  /// @param iconEnabledColor 启用状态图标颜色
  /// @param unselectedIcon 未选中状态的复选框图标
  /// @param selectedIcon 选中状态的复选框图标
  /// @param disabledIcon 禁用状态的复选框图标
  /// @param style 文本样式
  /// @param popUpLayerPadding 弹出层内边距
  /// @param popUpLayerTitleStyle 弹出层标题样式
  /// @param popUpLayerTitlePadding 弹出层标题内边距
  /// @param popUpLayerElevation 弹出层阴影高度
  /// @param popUpLayerShadowColor 弹出层阴影颜色
  /// @param disabledKeys 禁用的键
  /// @param itemPadding 选项项内边距
  /// @param itemStyle 选项项标题样式
  /// @param itemCheckedStyle 选项项选中状态标题样式
  /// @param itemDisabledStyle 选项项禁用状态标题样式
  /// @param itemTitlePadding 选项项标题内边距
  /// @return WFormMultiDropdownConfig 实例，包含更新后的配置
  WFormMultiDropdownConfig copyWith({
    bool? enabled,
    double? height,
    double? width,
    EdgeInsetsGeometry? contentPadding,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    InputDecoration? decoration,
    double? iconSize,
    Widget? icon,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    Widget? unselectedIcon,
    Widget? selectedIcon,
    Widget? disabledIcon,
    TextStyle? style,
    EdgeInsets? popUpLayerPadding,
    TextStyle? popUpLayerTitleStyle,
    EdgeInsets? popUpLayerTitlePadding,
    double? popUpLayerElevation,
    Color? popUpLayerShadowColor,
    String? disabledKeys,
    EdgeInsetsGeometry? itemPadding,
    TextStyle? itemStyle,
    TextStyle? itemCheckedStyle,
    TextStyle? itemDisabledStyle,
    EdgeInsets? itemTitlePadding,
  }) {
    final config = WFormMultiDropdownConfig();
    config._enabled = enabled ?? _enabled;
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._contentPadding = contentPadding ?? _contentPadding;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._decoration = decoration ?? _decoration;
    config._iconSize = iconSize ?? _iconSize;
    config._icon = icon ?? _icon;
    config._iconDisabledColor = iconDisabledColor ?? _iconDisabledColor;
    config._iconEnabledColor = iconEnabledColor ?? _iconEnabledColor;
    config._unselectedIcon = unselectedIcon ?? _unselectedIcon;
    config._selectedIcon = selectedIcon ?? _selectedIcon;
    config._disabledIcon = disabledIcon ?? _disabledIcon;
    config._style = style ?? _style;
    config._popUpLayerPadding = popUpLayerPadding ?? _popUpLayerPadding;
    config._popUpLayerTitleStyle = popUpLayerTitleStyle ?? _popUpLayerTitleStyle;
    config._popUpLayerTitlePadding = popUpLayerTitlePadding ?? _popUpLayerTitlePadding;
    config._popUpLayerElevation = popUpLayerElevation ?? _popUpLayerElevation;
    config._popUpLayerShadowColor = popUpLayerShadowColor ?? _popUpLayerShadowColor;
    config._disabledKeys = disabledKeys ?? _disabledKeys;
    config._itemPadding = itemPadding ?? _itemPadding;
    config._itemStyle = itemStyle ?? _itemStyle;
    config._itemCheckedStyle = itemCheckedStyle ?? _itemCheckedStyle;
    config._itemDisabledStyle = itemDisabledStyle ?? _itemDisabledStyle;
    config._itemTitlePadding = itemTitlePadding ?? _itemTitlePadding;
    return config;
  }

  /// 构建带有 WFormBorder 包装的 WFormMultiDropdown 组件
  ///
  /// @param T 选项值类型
  /// @param name 字段名称
  /// @param items 选项映射，键为值，值为显示文本
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param hintText 提示文本
  /// @param hintTextList 提示文本列表
  /// @param isTransparentBackground 是否透明背景
  /// @param key 组件键
  /// @param enableFocusBorder 是否启用焦点边框
  /// @return 带有 WFormBorder 包装的 WFormMultiDropdown 实例
  Widget buildBordered<T>({
    required String name,
    required Map<T, String> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
    String? hintText,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
  }) {
    // 验证 name 参数
    if (name.isEmpty) {
      throw Exception('字段名称不能为空');
    }

    // 构建基础组件
    final multiDropdown = build<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
    );

    // 使用 WFormBorder 包装
    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: !_enabled,
      enableFocusBorder: enableFocusBorder,
      child: multiDropdown,
    );
  }
}
