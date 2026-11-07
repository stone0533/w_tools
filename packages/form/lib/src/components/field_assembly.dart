import 'package:flutter/material.dart';

import 'border/read_only_scope.dart';
import 'field_frame.dart';

/// `message` 与 `hintTextList` 只允许二选一，同时传时直接断言。
void _assertHints(String? message, List<String>? hintTextList) {
  assert(
    message == null || hintTextList == null,
    'message 与 hintTextList 只需传一个（message 是便捷写法，不能与列表同时使用）。',
  );
}

/// 直接字段的公共装配：字段名校验 / 提示文案归一 / bordered 分支 / 只读作用域。
///
/// 所有直接字段都走这里，避免每个字段各写一份 `bordered` 分支、提示文案规则与
/// 同一段断言（原来 7 个字段各有一份，且 release 下断言被剥离后 message 会被静默丢弃）。
///
/// `message` 是 `hintTextList` 的单条便捷写法：二者只传一个，统一在这里归一成
/// 提示列表，字段侧不再各自拼 `[message]`。
Widget assembleFormField({
  required String name,
  required Widget child,
  bool bordered = true,
  bool readOnly = false,
  bool enableFocusBorder = true,
  String? message,
  List<String>? hintTextList,
  bool? isTransparentBackground,
}) {
  _assertHints(message, hintTextList);
  final hints = hintTextList ?? (message != null ? <String>[message] : null);
  if (name.isEmpty) {
    throw ArgumentError.value(name, 'name', '字段名称不能为空');
  }
  if (!bordered) {
    // 无边框时没有 errorBuilder / hintBuilder，但提示文案不能静默丢弃：
    // 直接在字段下方用默认文字样式渲染（release 同样生效）。
    Widget result = child;
    if (hints != null && hints.isNotEmpty) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Builder(
              builder: (context) => Text(
                hints.join('；'),
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }
    return readOnly ? WFormReadOnlyScope(readOnly: true, child: result) : result;
  }
  return WFormFieldFrame.border(
    name: name,
    hintTextList: hints,
    isTransparentBackground: isTransparentBackground,
    enableFocusBorder: enableFocusBorder,
    readOnly: readOnly,
    child: child,
  );
}
