// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';

/// 表单字段统一默认样式。
///
/// 放在 [WForm] 上，由直接字段构造读取；单个字段需要不同样式时用
/// [WFormFieldStyleScope] 包裹该字段。
/// 本类不可变，可以安全共享。
class WFormFieldStyle {
  const WFormFieldStyle({
    this.height,
    this.containerPadding,
    this.textStyle,
    this.placeholderStyle,
    // remove-in: 9.0.0
    @Deprecated('Use placeholderStyle instead. remove-in: 9.0.0') this.hintStyle,
  });

  final double? height;
  final EdgeInsetsGeometry? containerPadding;
  final TextStyle? textStyle;

  /// 占位符文字样式。
  final TextStyle? placeholderStyle;

  /// 历史占位符样式；用 [placeholderStyle]。构造参数已弃用（remove-in: 9.0.0）。
  // remove-in: 9.0.0
  @Deprecated('Use placeholderStyle instead. remove-in: 9.0.0')
  final TextStyle? hintStyle;

  /// 兼容新旧字段的实际占位符样式。
  TextStyle? get effectiveHintStyle => placeholderStyle ?? hintStyle;

  /// 复制并覆盖部分字段；未传的字段沿用当前值。
  ///
  /// [WFormFieldStyleScope] 默认整体替换页面样式，所以「只改一个字段的高度」要
  /// 从页面样式派生完整样式：
  ///
  /// ```dart
  /// WFormFieldStyleScope(
  ///   style: pageStyle.copyWith(height: 72),
  ///   child: const WFormTextField(name: 'bio', maxLines: 3),
  /// )
  /// ```
  WFormFieldStyle copyWith({
    double? height,
    EdgeInsetsGeometry? containerPadding,
    TextStyle? textStyle,
    TextStyle? placeholderStyle,
    // remove-in: 9.0.0
    @Deprecated('Use placeholderStyle instead. remove-in: 9.0.0') TextStyle? hintStyle,
  }) {
    return WFormFieldStyle(
      height: height ?? this.height,
      containerPadding: containerPadding ?? this.containerPadding,
      textStyle: textStyle ?? this.textStyle,
      placeholderStyle: placeholderStyle ?? this.placeholderStyle,
      hintStyle: hintStyle ?? this.hintStyle,
    );
  }

  /// 读取当前生效的字段样式；没有 WForm / scope 时返回 null。
  ///
  /// 最近一层 scope 开启 [WFormFieldStyleScope.mergeWithParent] 时，会继续向外
  /// 逐层合并（内层非 null 字段覆盖外层），直到遇到「整体替换」的 scope 或树顶。
  static WFormFieldStyle? of(BuildContext context) {
    final nearest = context.dependOnInheritedWidgetOfExactType<WFormFieldStyleScope>();
    if (nearest == null || !nearest.mergeWithParent) {
      return nearest?.style;
    }

    // 从最近一层开始，逐层向外合并；同时注册对外层样式的依赖，
    // 保证页面 fieldStyle 运行期变化时字段会重建。
    var merged = nearest.style;
    var skippedNearest = false;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is! WFormFieldStyleScope) return true;
      if (!skippedNearest) {
        skippedNearest = true;
        return true;
      }
      if (element is InheritedElement) {
        context.dependOnInheritedElement(element);
      }
      merged = _mergeStyles(widget.style, merged);
      // 外层是整体替换：它就是这个作用域的完整基线，不再继续往外找。
      return widget.mergeWithParent;
    });
    return merged;
  }

  @override
  bool operator ==(Object other) =>
      other is WFormFieldStyle &&
      other.height == height &&
      other.containerPadding == containerPadding &&
      other.textStyle == textStyle &&
      other.placeholderStyle == placeholderStyle &&
      other.hintStyle == hintStyle;

  @override
  int get hashCode => Object.hash(height, containerPadding, textStyle, placeholderStyle, hintStyle);
}

// 9.0 计划（见 docs/analysis/2026-11-23-form-field-style-scope-9.0.md）：
// 改成 StatelessWidget + 私有 InheritedWidget，简化 of() 的祖先遍历；会删除公开的
// updateShouldNotify，因此只能随 major 做；默认替换 / mergeWithParent 等行为不变。
/// 覆盖一棵子树内直接字段的 [WFormFieldStyle]。
///
/// **默认整体替换**外层 `WForm.fieldStyle`：作用域里未设置的字段不再继承页面样式
/// （`style: null` 表示清空）。
///
/// 只改一个字段的某几项时，传 `mergeWithParent: true`，未设置的字段沿用外层
/// （对应 Flutter 的 `DefaultTextStyle.merge` / `IconTheme.merge` 风格）：
///
/// ```dart
/// // 只改高度，其余（padding / 文字 / 占位样式）沿用页面样式
/// WFormFieldStyleScope(
///   style: const WFormFieldStyle(height: 72),
///   mergeWithParent: true,
///   child: const WFormTextField(name: 'bio', maxLines: 3),
/// )
/// ```
///
/// 也可以从页面样式显式派生完整样式（适合需要清空某一项、或依赖关系要显式可见）：
/// `style: pageStyle.copyWith(height: 72)`。
///
/// 合并只发生在「当前生效的父样式」上：外层如果也是整体替换的 scope，
/// 合并到它为止，更外层的样式不再参与。
class WFormFieldStyleScope extends InheritedWidget {
  const WFormFieldStyleScope({
    super.key,
    required this.style,
    this.mergeWithParent = false,
    required super.child,
  });

  /// 本作用域的样式；`null` 表示清空页面样式（[mergeWithParent] 为 true 时表示
  /// 不覆盖、完全沿用外层）。
  final WFormFieldStyle? style;

  /// 是否与当前生效的外层字段样式逐字段合并。
  ///
  /// 默认 `false`：整体替换外层样式（既有行为）。
  /// `true`：本作用域里非 null 的字段覆盖外层，其余沿用外层；
  /// 外层没有样式时等同直接传 [style]。
  ///
  /// 注意：合并规则是「null = 沿用」，所以它不能用来把某一项改回空；
  /// 要清空 / 完全接管请用默认的整体替换。
  final bool mergeWithParent;

  @override
  bool updateShouldNotify(WFormFieldStyleScope oldWidget) {
    return style != oldWidget.style || mergeWithParent != oldWidget.mergeWithParent;
  }
}

/// 逐字段合并：`child` 中非 null 的字段覆盖 `parent`，其余沿用父样式。
WFormFieldStyle? _mergeStyles(WFormFieldStyle? parent, WFormFieldStyle? child) {
  if (parent == null) return child;
  if (child == null) return parent;
  return WFormFieldStyle(
    height: child.height ?? parent.height,
    containerPadding: child.containerPadding ?? parent.containerPadding,
    textStyle: child.textStyle ?? parent.textStyle,
    placeholderStyle: child.placeholderStyle ?? parent.placeholderStyle,
    hintStyle: child.hintStyle ?? parent.hintStyle,
  );
}
