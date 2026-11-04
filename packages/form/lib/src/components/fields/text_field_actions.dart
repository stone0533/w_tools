// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';

import '../form_icons.dart';
import '../form_theme.dart';
import 'text_field.dart';

/// 表单文本框 action 的通用实现
///
/// 封装了「取状态 → 订阅值变化 → 条件显示 → 点击处理」这套样板，
/// 调用方只需描述图标与点击行为：
///
/// ```dart
/// WFormTextFieldAction(
///   visibleWhen: (data) => data.hasText,
///   iconBuilder: (data) => Icon(data.hasText ? Icons.send : Icons.send_outlined),
///   onPressed: (data) => submit(data.value!),
/// )
/// ```
class WFormTextFieldAction extends StatelessWidget {
  /// 图标构建器（可读取当前状态，动态决定图标）
  final Widget Function(WFormTextFieldData data) iconBuilder;

  /// 点击回调（可读取当前状态）；为 null 时不可点击
  final void Function(WFormTextFieldData data)? onPressed;

  /// 是否显示（默认始终显示），随输入值变化重新求值
  final bool Function(WFormTextFieldData data)? visibleWhen;

  const WFormTextFieldAction({
    super.key,
    required this.iconBuilder,
    this.onPressed,
    this.visibleWhen,
  });

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldScope.of(context);
    if (data == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: data.valueListenable,
      builder: (context, _) {
        if (!(visibleWhen?.call(data) ?? true)) {
          return const SizedBox.shrink();
        }

        final icon = iconBuilder(data);
        if (onPressed == null) return icon;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onPressed!(data),
            behavior: HitTestBehavior.opaque,
            child: icon,
          ),
        );
      },
    );
  }
}

/// 密码可见/隐藏切换按钮（预置 action）
///
/// 放入 [WFormTextFieldConfig.actions] 列表即可。图标从
/// [WFormIcons.defaults.obscureText] / [WFormIcons.defaults.obscureTextVisible] 取全局默认。
///
/// ```dart
/// WFormTextFieldCore(
///   config: WFormTextFieldConfig()
///     ..obscureText = true
///     ..actions = const [WFormTextFieldPasswordToggle()],
///   name: 'password',
/// )
/// ```
class WFormTextFieldPasswordToggle extends StatelessWidget {
  const WFormTextFieldPasswordToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.obscureText,
      iconBuilder: (data) {
        final theme = WFormTheme.maybeOf(context);
        return data.isPasswordVisible
            ? theme?.effectiveObscureTextVisibleIcon ?? WFormIcons.defaults.obscureTextVisible
            : theme?.effectiveObscureTextIcon ?? WFormIcons.defaults.obscureText;
      },
      onPressed: (data) => data.togglePasswordVisibility(),
    );
  }
}

/// 清空文本按钮（预置 action）
///
/// 仅当文本框有内容且非只读时可见。点击清空字段值，并回调 [onCleared]。
/// 内部订阅 [WFormTextFieldData.valueListenable]，无需额外状态管理。
class WFormTextFieldClearButton extends StatelessWidget {
  /// 点击清空后的额外回调
  ///
  /// 仅按钮点击触发；通过 `data.clear()` 等编程式方式清空不会触发。
  final VoidCallback? onCleared;

  /// 自定义图标，默认取 [WFormIcons.defaults.clear]
  ///
  /// 点击热区与图标的渲染尺寸一致；需要更大热区请传入更大的图标，
  /// 或用 SizedBox 包裹图标来扩大点击区域。
  final Widget? icon;

  const WFormTextFieldClearButton({
    super.key,
    this.onCleared,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.hasText && !data.readOnly,
      iconBuilder: (_) {
        final theme = WFormTheme.maybeOf(context);
        return icon ?? theme?.effectiveClearButtonIcon ?? WFormIcons.defaults.clear;
      },
      onPressed: (data) {
        data.clear();
        onCleared?.call();
      },
    );
  }
}
