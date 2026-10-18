import 'package:flutter/services.dart';

/// 常用文本输入格式化器集合
///
/// 可直接用于 `TextField.inputFormatters`，也可作为自定义格式化器的参考：
/// - `FilteringTextInputFormatter.allow(...)`：白名单，只允许符合规则的字符
/// - `FilteringTextInputFormatter.deny(...)`：黑名单，除规定字符外均可输入
/// - `LengthLimitingTextInputFormatter(...)`：长度限制
/// - `FilteringTextInputFormatter.digitsOnly`：只允许数字
/// - `FilteringTextInputFormatter.singleLineFormatter`：屏蔽换行符
///
/// 正则示例：
/// - `RegExp("[-_\u4E00-\u9FA5a-zA-Z0-9]")`：允许中英文、数字、下划线与短横线
/// - `RegExp("[a-zA-Z]")`：只允许字母
/// - `RegExp("^[a-z0-9A-Z]+")`：只允许数字与字母
class WInputFormatters {
  /// 香港电话号码格式化器
  ///
  /// 最多 8 位数字，每 4 位用空格分隔（格式化后总长度上限 9）。
  static List<TextInputFormatter> phone() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      WCardNumberInputFormatter(),
      LengthLimitingTextInputFormatter(9),
    ];
  }
}

/// 通用分隔符输入格式化器
///
/// 在文本输入时按照指定规则添加分隔符。
class WDividerInputFormatter extends TextInputFormatter {
  /// 第一个分割位数
  final int first;

  /// 后续分割位数
  final int rear;

  /// 分割符
  final String pattern;

  /// 创建分隔符格式化器
  ///
  /// [first] 默认 3，[rear] 默认 4，[pattern] 默认空格。
  WDividerInputFormatter({this.first = 3, this.rear = 4, this.pattern = ' '});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 不含分隔符的文本
    String allTextPure = newValue.text.replaceAll(RegExp(RegExp.escape(pattern)), '');
    // 处理后含分隔符的文本
    String allTextDeal = '';
    int cursorPosition = newValue.selection.baseOffset;

    for (int i = 0; i < allTextPure.length; i++) {
      // 在 i 处插入分隔符：i>0 且已越过首段（i>=first）且间隔为 rear 的整数倍
      if (i > 0 && i >= first && (i - first) % rear == 0) {
        allTextDeal = '$allTextDeal$pattern';
      }
      allTextDeal += allTextPure[i];
    }

    // 光标在文本末尾：保持在最后
    if (cursorPosition >= newValue.text.length) {
      return TextEditingValue(
        text: allTextDeal,
        selection: TextSelection.collapsed(offset: allTextDeal.length),
      );
    }

    // 光标不在末尾：仅在新增字符时判断是否需要右移，
    // 否则删除分隔符后一位的字符会被误判为「左侧新增分隔符」
    if (newValue.text.length > oldValue.text.length &&
        cursorPosition > 0 &&
        allTextDeal.startsWith(pattern, cursorPosition - 1)) {
      cursorPosition += pattern.length;
      if (cursorPosition > allTextDeal.length) {
        cursorPosition = allTextDeal.length;
      }
    }
    return TextEditingValue(
      text: allTextDeal,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// 银行卡号输入格式化器
///
/// 每 4 位添加一个空格，如 `1234 1234 1234 1234 123`。
class WCardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String inputData = newValue.text.replaceAll(RegExp(r'\s'), '');
    StringBuffer stringBuffer = StringBuffer();
    int cursorPosition = newValue.selection.baseOffset;

    for (int i = 0; i < inputData.length; i++) {
      stringBuffer.write(inputData[i]);
      int index = i + 1;
      // 每四位插入一个空格，末尾不加
      if (index % 4 == 0 && inputData.length != index) {
        stringBuffer.write(' ');
      }
    }

    final String result = stringBuffer.toString();

    // 光标在文本末尾：保持在最后
    if (cursorPosition >= newValue.text.length) {
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }

    // 光标不在末尾：仅在新增字符时判断是否需要右移，
    // 否则删除空格后一位的字符会被误判为「左侧新增空格」
    if (newValue.text.length > oldValue.text.length &&
        cursorPosition > 0 &&
        result.startsWith(' ', cursorPosition - 1)) {
      cursorPosition++;
    }
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
