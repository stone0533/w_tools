import 'package:flutter/material.dart';

import 'border/read_only_scope.dart';
import 'field_frame.dart';

/// 直接字段的公共装配：bordered 分支 / 只读作用域 / 字段名校验。
///
/// 所有直接字段都走这里，避免每个字段各写一份 `bordered` 分支与同一段断言
/// （原来 7 个字段各有一份，且 release 下断言被剥离后 message 会被静默丢弃）。
Widget assembleFormField({
  required String name,
  required Widget child,
  bool bordered = true,
  bool readOnly = false,
  bool enableFocusBorder = true,
  List<String>? hintTextList,
  bool? isTransparentBackground,
}) {
  if (name.isEmpty) {
    throw ArgumentError.value(name, 'name', '字段名称不能为空');
  }
  if (!bordered) {
    // 无边框时没有 errorBuilder / hintBuilder，但提示文案不能静默丢弃：
    // 直接在字段下方用默认文字样式渲染（release 同样生效）。
    Widget result = child;
    if (hintTextList != null && hintTextList.isNotEmpty) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Builder(
              builder: (context) => Text(
                hintTextList.join('；'),
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
    hintTextList: hintTextList,
    isTransparentBackground: isTransparentBackground,
    enableFocusBorder: enableFocusBorder,
    readOnly: readOnly,
    child: child,
  );
}
