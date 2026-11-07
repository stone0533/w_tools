import 'package:flutter/widgets.dart';
import 'package:w_tools_form/src/components/border/border.dart';

/// 测试专用：从 `GlobalKey` 取出已隐藏的 `WFormBorderState`。
///
/// `WFormBorderState` 6.0 起不再从 barrel 导出；公开行为测试只通过它调用
/// `setError` / 读取 error 状态，不把它写进公开契约。
WFormBorderState? borderStateOf(GlobalKey key) => key.currentState as WFormBorderState?;
