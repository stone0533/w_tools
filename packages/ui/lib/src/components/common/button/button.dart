import 'package:flutter/material.dart';

import '../../../internal/ui_strings.dart';
import '../../text/icon_text.dart';
import 'button_size.dart';
import 'button_theme.dart';

export 'button_size.dart';
export 'button_theme.dart';

/// 按钮类型（构造器决定，不再作为公开参数）。
enum _WButtonKind { filled, outlined, text }

/// 按钮。
///
/// 视觉完全交给 Material [ButtonStyle]（`FilledButton` / `OutlinedButton` /
/// `TextButton`），因此主题、水波纹、键盘 / 焦点、禁用态都与 Material 一致；
/// 全站样式用 `WButtonTheme`，单个按钮用 [style] 覆盖。
///
/// 构造器只表达按钮类型：
/// - [WButton.filled]：主按钮（`FilledButton`）；
/// - [WButton.outlined]：描边按钮（`OutlinedButton`）；
/// - [WButton.text]：文字按钮（`TextButton`）。
///
/// 危险色不是类型，用 `WButton.filled(style: ...)` 或项目 `AppButtons.danger` 表达。
///
/// 只负责按钮语义、loading、最小尺寸与图标 + 文字内容。
class WButton extends StatelessWidget {
  /// 主按钮（`FilledButton`）。
  const WButton.filled({
    super.key,
    this.style,
    this.size = WButtonSize.medium,
    this.label,
    this.icon,
    this.content,
    this.loading = false,
    this.loadingBuilder,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.loadingLabel = '',
    this.tooltip,
    this.isSelected,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _WButtonKind.filled,
       assert(
         content != null || label != null || icon != null,
         'WButton: content / label / icon 至少提供一个',
       ),
       assert(
         content == null || (label == null && icon == null),
         'WButton: content 与 label + icon 只能选择一种',
       ),
       assert(
         !enabled || loading || onTap != null || onLongPress != null,
         'WButton: 可交互按钮至少提供 onTap 或 onLongPress',
       ),
       assert(
         icon == null || label != null || content != null || semanticLabel != null || loading,
         'WButton: 纯图标按钮请提供 semanticLabel',
       );

  /// 描边按钮（`OutlinedButton`）。
  const WButton.outlined({
    super.key,
    this.style,
    this.size = WButtonSize.medium,
    this.label,
    this.icon,
    this.content,
    this.loading = false,
    this.loadingBuilder,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.loadingLabel = '',
    this.tooltip,
    this.isSelected,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _WButtonKind.outlined,
       assert(
         content != null || label != null || icon != null,
         'WButton: content / label / icon 至少提供一个',
       ),
       assert(
         content == null || (label == null && icon == null),
         'WButton: content 与 label + icon 只能选择一种',
       ),
       assert(
         !enabled || loading || onTap != null || onLongPress != null,
         'WButton: 可交互按钮至少提供 onTap 或 onLongPress',
       ),
       assert(
         icon == null || label != null || content != null || semanticLabel != null || loading,
         'WButton: 纯图标按钮请提供 semanticLabel',
       );

  /// 文字按钮（`TextButton`）。
  const WButton.text({
    super.key,
    this.style,
    this.size = WButtonSize.medium,
    this.label,
    this.icon,
    this.content,
    this.loading = false,
    this.loadingBuilder,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.loadingLabel = '',
    this.tooltip,
    this.isSelected,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _WButtonKind.text,
       assert(
         content != null || label != null || icon != null,
         'WButton: content / label / icon 至少提供一个',
       ),
       assert(
         content == null || (label == null && icon == null),
         'WButton: content 与 label + icon 只能选择一种',
       ),
       assert(
         !enabled || loading || onTap != null || onLongPress != null,
         'WButton: 可交互按钮至少提供 onTap 或 onLongPress',
       ),
       assert(
         icon == null || label != null || content != null || semanticLabel != null || loading,
         'WButton: 纯图标按钮请提供 semanticLabel',
       );

  final _WButtonKind _kind;

  /// 单按钮样式覆盖（Material [ButtonStyle]）；优先级高于 [size] 与 `WButtonTheme`。
  final ButtonStyle? style;

  /// 尺寸令牌；默认 `WButtonSize.medium`。
  final WButtonSize size;

  /// 简单内容
  final String? label;
  final IconData? icon;

  /// 静态复杂内容；内部 Text / Icon 继承按钮前景色与文字样式。
  final Widget? content;

  final bool loading;

  /// 加载中占位；默认小号 CircularProgressIndicator
  final WidgetBuilder? loadingBuilder;

  final bool enabled;

  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  /// 显式无障碍标签；纯图标按钮建议提供。
  ///
  /// 提供后会替代按钮内容的朗读，并保留 `button` / `enabled` 语义。
  final String? semanticLabel;

  /// 无障碍提示（操作后会发生什么）。
  final String? semanticHint;

  /// loading 时的读屏文案；空字符串表示按当前 `Locale` 使用内置文案
  /// （zh：加载中；其他：Loading）。
  final String loadingLabel;

  /// 长按 / hover 提示文案；null 时不包 Tooltip。
  final String? tooltip;

  /// 是否处于选中态（toggle button）；进入 `Semantics.selected`。
  final bool? isSelected;

  final FocusNode? focusNode;
  final bool autofocus;

  bool get _interactive => enabled && !loading && (onTap != null || onLongPress != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTheme = WButtonTheme.of(context);
    final themed = switch (_kind) {
      _WButtonKind.filled => buttonTheme.filled!,
      _WButtonKind.outlined => buttonTheme.outlined!,
      _WButtonKind.text => buttonTheme.text!,
    };
    // 优先级：单按钮 style > WButtonSize > WButtonTheme。
    // ButtonStyle.merge 是「this 优先」，所以按低 → 高依次 merge。
    final sized = _withSize(size, themed, theme);
    final style = (this.style ?? const ButtonStyle()).merge(sized);

    final interactive = _interactive;
    final onPressed = interactive ? (onTap ?? _noop) : null;

    final body = Builder(
      builder: (context) {
        final child = content ?? _buildButtonLabel(this);
        return loading ? _buildButtonLoading(context, child, loadingLabel) : child;
      },
    );

    Widget button = switch (_kind) {
      _WButtonKind.filled => FilledButton(
        style: style,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        child: body,
      ),
      _WButtonKind.outlined => OutlinedButton(
        style: style,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        child: body,
      ),
      _WButtonKind.text => TextButton(
        style: style,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        child: body,
      ),
    };

    if (isSelected != null) {
      button = Semantics(selected: isSelected, child: button);
    }

    final semanticText = semanticLabel;
    if (semanticText != null || semanticHint != null) {
      // 有 semanticLabel / hint 时内层会被 excludeSemantics 丢弃，loading 的
      // liveRegion 也一起消失。这里把 loading 文案并入 label，并让该节点
      // 自己成为 liveRegion，读屏才能听到「保存，加载中」。
      final loadingText = loading ? _resolvedLoadingLabel(context, loadingLabel) : null;
      final label = <String>[
        if (semanticText != null) semanticText,
        if (loadingText != null) loadingText,
      ].join(_semanticSeparator(context));
      button = Semantics(
        button: true,
        enabled: interactive,
        label: label.isEmpty ? null : label,
        hint: semanticHint,
        liveRegion: loading,
        excludeSemantics: true,
        child: button,
      );
    }

    final tip = tooltip;
    if (tip == null) {
      return onLongPress == null
          ? button
          : GestureDetector(
              onLongPress: interactive ? onLongPress : null,
              child: button,
            );
    }

    // Tooltip 在外层，它的长按识别器会被内层 GestureDetector 抢走；长按回调里
    // 手动 ensureTooltipVisible，保证 tooltip 与 onLongPress 能同时生效。
    return Tooltip(
      message: tip,
      excludeFromSemantics: true,
      child: Builder(
        builder: (tooltipContext) {
          if (onLongPress == null) return button;
          return GestureDetector(
            onLongPress: interactive
                ? () {
                    onLongPress!();
                    tooltipContext.findAncestorStateOfType<TooltipState>()?.ensureTooltipVisible();
                  }
                : null,
            child: button,
          );
        },
      ),
    );
  }

  static void _noop() {}

  static ButtonStyle _withSize(WButtonSize size, ButtonStyle base, ThemeData theme) {
    size.validate();
    return ButtonStyle(
      padding: size.padding == null ? null : WidgetStatePropertyAll(size.padding),
      minimumSize: WidgetStatePropertyAll(
        Size(size.minWidth ?? 48, size.minHeight ?? 48),
      ),
      tapTargetSize: size.tapTargetSize >= 48
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStateProperty.resolveWith((states) {
        final text =
            base.textStyle?.resolve(states) ?? theme.textTheme.labelLarge ?? const TextStyle();
        return text.copyWith(
          fontSize: size.fontSize,
          fontWeight: size.fontWeight,
          height: size.lineHeight,
          letterSpacing: size.letterSpacing,
        );
      }),
    ).merge(base);
  }
}

/// 语义文案连接符：中文用全角逗号，其他语言用英文逗号。
String _semanticSeparator(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'zh' ? '，' : ', ';

/// loading 的读屏文案：空字符串走内置本地化文案。
String _resolvedLoadingLabel(BuildContext context, String loadingLabel) =>
    loadingLabel.isEmpty ? WUiStrings.of(context).loadingLabel : loadingLabel;

/// 加载中占位（spinner 跟随按钮前景色，保持原内容占位避免尺寸跳动）。
Widget _buildButtonLoading(
  BuildContext context,
  Widget child,
  String loadingLabel,
) {
  // 默认 spinner 取 colorScheme.primary；在主色填充按钮上会与背景同色。
  final indicatorColor = DefaultTextStyle.of(context).style.color;
  final label = _resolvedLoadingLabel(context, loadingLabel);
  return Stack(
    alignment: Alignment.center,
    children: [
      ExcludeSemantics(child: Opacity(opacity: 0, child: child)),
      Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: indicatorColor,
          ),
        ),
      ),
    ],
  );
}

/// 默认内容：图标 + 文字一行（与独立 `WIconText` 同一套行盒对齐）。
Widget _buildButtonLabel(WButton button) {
  final label = button.label;
  final icon = button.icon;
  final size = button.size;
  final iconSize = size.iconSize ?? 18;
  final gap = size.gap ?? 8;
  if (label != null && icon != null) {
    return WIconText(
      icon: icon,
      text: label,
      iconSize: iconSize,
      gap: gap,
    );
  }
  if (icon != null) return Icon(icon, size: iconSize);
  if (label != null) return Text(label);
  return const SizedBox.shrink();
}
