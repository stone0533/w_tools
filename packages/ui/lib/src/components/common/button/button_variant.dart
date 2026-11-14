/// 按钮语义变体。
///
/// 视觉由 `WButtonTheme` 对应的 `ButtonStyle` 决定；默认值从 `ColorScheme` 派生：
/// `filled` = primary/onPrimary，`outlined` = primary 前景 + outline 边框，
/// `text` = primary 前景，`danger` = error/onError。
enum WButtonVariant {
  filled,
  outlined,
  text,
  danger,
}
