import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:w_tools/w.dart';

/// 表单下拉选择组件
class WFormDropdown<T> extends StatelessWidget {
  /// 下拉选择配置
  final WFormDropdownConfig config;

  /// 字段名称
  final String name;

  /// 选项映射，键为值，值为显示文本
  final Map<T, String> items;

  /// 初始值
  final T? initialValue;

  /// 值变化回调
  final ValueChanged<T?>? onChanged;

  /// 提示文本
  final Widget? hint;

  /// 提示文本
  final String? hintText;

  /// 是否启用
  final bool enabled;

  /// 宽度
  final double? width;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 下拉选择配置
  /// @param name 字段名称
  /// @param items 选项映射
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param hint 提示文本
  /// @param hintText 提示文本
  /// @param enabled 是否启用
  /// @param width 宽度
  const WFormDropdown({
    super.key,
    required this.config,
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.hintText,
    this.enabled = true,
    this.width,
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

    Widget? hintWidget;

    if (hint != null) {
      hintWidget = hint;
    } else if (hintText != null) {
      hintWidget = Center(child: Text(hintText!, style: config._hintStyle));
    } else if (config._hint != null) {
      hintWidget = config._hint;
    }

    return Container(
      height: config._height,
      width: width ?? config._width,
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
              child: FormBuilderDropdown<T>(
                name: name,
                items: items.entries
                    .map(
                      (e) => DropdownMenuItem<T>(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: config._style,
                          strutStyle: const StrutStyle(forceStrutHeight: true),
                        ),
                      ),
                    )
                    .toList(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: config._contentPadding,
                ),
                initialValue: initialValue,
                icon: config._icon ?? WConfig.dropdownIcon,
                onChanged: onChangedHandler,
                hint: hintWidget,
                enabled: enabled,
                dropdownColor: config._dropdownColor,
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

/// 下拉选择配置类，定义下拉选择的样式和行为
class WFormDropdownConfig {
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

  /// 提示文本
  Widget? _hint;

  /// 图标
  Widget? _icon;

  /// 标签样式
  TextStyle? _style;

  /// 提示文本样式
  TextStyle? _hintStyle;

  /// 下拉弹出层背景色
  Color? _dropdownColor;

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

  /// 提示文本 setter
  set hint(Widget? value) {
    _hint = value;
  }

  /// 图标 setter
  set icon(Widget? value) {
    _icon = value;
  }

  /// 标签样式 setter
  set style(TextStyle? value) {
    _style = value;
  }

  /// 提示文本样式 setter
  set hintStyle(TextStyle? value) {
    _hintStyle = value;
  }

  /// 下拉弹出层背景色 setter
  set dropdownColor(Color? value) {
    _dropdownColor = value;
  }

  /// 构建 WFormDropdown 组件
  ///
  /// @param T 选项值类型
  /// @param name 字段名称
  /// @param items 选项映射，键为值，值为显示文本
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param hint 提示文本
  /// @param hintText 提示文本
  /// @param enabled 是否启用
  /// @param width 宽度
  /// @return WFormDropdown 实例
  WFormDropdown<T> build<T>({
    required String name,
    required Map<T, String> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
    Widget? hint,
    String? hintText,
    bool enabled = true,
    double? width,
  }) {
    return WFormDropdown<T>(
      config: this,
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      hint: hint,
      hintText: hintText,
      enabled: enabled,
      width: width,
    );
  }

  /// 复制配置
  ///
  /// @return 新的配置实例
  WFormDropdownConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param height 高度
  /// @param width 宽度
  /// @param contentPadding 内容内边距
  /// @param yOffset Y轴偏移
  /// @param leading 左侧组件
  /// @param actions 操作按钮列表
  /// @param containerDecoration 容器装饰
  /// @param containerMargin 容器边距
  /// @param containerPadding 容器内边距
  /// @param hint 提示文本
  /// @param icon 图标
  /// @param style 标签样式
  /// @param hintStyle 提示文本样式
  /// @param dropdownColor 下拉弹出层背景色
  /// @return WFormDropdownConfig 实例，包含更新后的配置
  WFormDropdownConfig copyWith({
    double? height,
    double? width,
    EdgeInsetsGeometry? contentPadding,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
    Widget? hint,
    Widget? icon,
    TextStyle? style,
    TextStyle? hintStyle,
    Color? dropdownColor,
  }) {
    final config = WFormDropdownConfig();
    config._height = height ?? _height;
    config._width = width ?? _width;
    config._contentPadding = contentPadding ?? _contentPadding;
    config._yOffset = yOffset ?? _yOffset;
    config._leading = leading ?? _leading;
    config._actions = actions ?? _actions;
    config._containerDecoration = containerDecoration ?? _containerDecoration;
    config._containerMargin = containerMargin ?? _containerMargin;
    config._containerPadding = containerPadding ?? _containerPadding;
    config._hint = hint ?? _hint;
    config._icon = icon ?? _icon;
    config._style = style ?? _style;
    config._hintStyle = hintStyle ?? _hintStyle;
    config._dropdownColor = dropdownColor ?? _dropdownColor;
    return config;
  }

  /// 构建带有 WFormBorder 包装的 WFormDropdown 组件
  ///
  /// @param T 选项值类型
  /// @param name 字段名称
  /// @param items 选项映射，键为值，值为显示文本
  /// @param initialValue 初始值
  /// @param onChanged 值变化回调
  /// @param hint 提示文本
  /// @param hintText 提示文本
  /// @param enabled 是否启用
  /// @param width 宽度
  /// @param hintTextList 提示文本列表
  /// @param isTransparentBackground 是否透明背景
  /// @param key 组件键
  /// @param enableFocusBorder 是否启用焦点边框
  /// @return 带有 WFormBorder 包装的 WFormDropdown 实例
  Widget buildBordered<T>({
    required String name,
    required Map<T, String> items,
    T? initialValue,
    ValueChanged<T?>? onChanged,
    Widget? hint,
    String? hintText,
    bool enabled = true,
    double? width,
    List<String>? hintTextList,
    bool? isTransparentBackground,
    Key? key,
    bool enableFocusBorder = true,
  }) {
    // 验证 name 参数
    if (name.isEmpty) {
      throw Exception('字段名称不能为空');
    }

    containerDecoration = null;

    final dropdown = build<T>(
      name: name,
      items: items,
      initialValue: initialValue,
      onChanged: onChanged,
      hint: hint,
      hintText: hintText,
      enabled: enabled,
      width: width,
    );

    return WFormBorderWithData(
      key: key,
      name: name,
      hintTextList: hintTextList,
      isTransparentBackground: isTransparentBackground,
      readOnly: !enabled,
      enableFocusBorder: enableFocusBorder,
      child: dropdown,
    );
  }
}
