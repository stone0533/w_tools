import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../form_icons.dart';
import '../form_theme.dart';
import 'text_field.dart';

/// 表单文本框 action 的通用实现
///
/// 封装了「取状态 → 订阅值变化 → 条件显示 → 点击处理」这套样板，
/// 调用方只需描述图标与点击行为。action 可聚焦，Enter / Space 会触发
/// [onPressed]；读屏标签优先用 [semanticLabel] / [semanticLabelBuilder]，
/// 也可以给图标自带 `semanticLabel`。
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

  /// 读屏使用的按钮标签；null 时回退到图标自身的语义
  final String? semanticLabel;

  /// 按当前输入状态生成读屏标签；非 null 时优先于 [semanticLabel]
  final String? Function(WFormTextFieldData data)? semanticLabelBuilder;

  const WFormTextFieldAction({
    super.key,
    required this.iconBuilder,
    this.onPressed,
    this.visibleWhen,
    this.semanticLabel,
    this.semanticLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldData.of(context);
    if (data == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: data.valueListenable,
      builder: (context, _) {
        if (!(visibleWhen?.call(data) ?? true)) {
          return const SizedBox.shrink();
        }

        final icon = iconBuilder(data);
        if (onPressed == null) return icon;

        void activate() => onPressed!(data);

        return Semantics(
          button: true,
          label: semanticLabelBuilder?.call(data) ?? semanticLabel,
          onTap: activate,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  activate();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              onTap: activate,
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              child: icon,
            ),
          ),
        );
      },
    );
  }
}

/// 密码可见/隐藏切换按钮（预置 action）
///
/// 放入直接字段的 `actions` 列表即可。图标从
/// [WFormIcons.defaults.obscureText] / [WFormIcons.defaults.obscureTextVisible] 取全局默认。
/// 读屏文案用 [showSemanticLabel] / [hideSemanticLabel]；不传时回退到图标语义。
///
/// ```dart
/// WFormTextField(
///   name: 'password',
///   obscureText: true,
///   actions: const [WFormTextFieldPasswordToggle()],
/// )
/// ```
class WFormTextFieldPasswordToggle extends StatelessWidget {
  /// 密码隐藏时（点击后显示密码）的读屏标签
  final String? showSemanticLabel;

  /// 密码可见时（点击后隐藏密码）的读屏标签
  final String? hideSemanticLabel;

  const WFormTextFieldPasswordToggle({
    super.key,
    this.showSemanticLabel,
    this.hideSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.obscureText,
      semanticLabelBuilder: (data) =>
          data.isPasswordVisible ? hideSemanticLabel : showSemanticLabel,
      iconBuilder: (data) {
        final theme = WFormThemeData.of(context);
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
/// 读屏文案用 [semanticLabel]；不传时回退到本地化 `clearButtonTooltip`。
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

  /// 读屏使用的按钮标签；null 时回退到本地化的 `clearButtonTooltip`
  final String? semanticLabel;

  const WFormTextFieldClearButton({
    super.key,
    this.onCleared,
    this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return WFormTextFieldAction(
      visibleWhen: (data) => data.hasText && !data.readOnly,
      semanticLabel:
          semanticLabel ??
          Localizations.of<MaterialLocalizations>(
            context,
            MaterialLocalizations,
          )?.clearButtonTooltip,
      iconBuilder: (_) {
        final theme = WFormThemeData.of(context);
        return icon ?? theme?.effectiveClearButtonIcon ?? WFormIcons.defaults.clear;
      },
      onPressed: (data) {
        data.clear();
        onCleared?.call();
      },
    );
  }
}
