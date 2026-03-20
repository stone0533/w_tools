import 'package:flutter/services.dart';

/// 文本输入格式化器工具类
///
/// 常用的文本输入格式化器：
/// - FilteringTextInputFormatter.allow（） (白名单校验)，表示只允许输入符合规则的字符 ;
/// - FilteringTextInputFormatter.deny（）（黑名单校验)，除了规定的字符,其他都可以输入;
/// - LengthLimitingTextInputFormatter ()，（长度限制）
/// - FilteringTextInputFormatter.digitsOnly  (只能输入数字)
/// - FilteringTextInputFormatter.singleLineFormatter  (屏蔽换行符，这样点击Return键，就不会再插入'\n'了)
/// - FilteringTextInputFormatter.allow(RegExp("[-_\u4E00-\u9FA5a-zA-Z0-9]"))
/// - FilteringTextInputFormatter(RegExp("[a-zA-Z]"))  (只允许输入字母)
/// - FilteringTextInputFormatter(RegExp("^[a-z0-9A-Z]+"))  (只允许输入数字，字母)

class WnnTextInputFormatter {
  /// 获取香港电话号码输入格式化器
  /// 格式：8位数，每四个数用空格分割
  ///
  /// @return 输入格式化器列表
  static List phone() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      CardNumberInputFormatter(),
      LengthLimitingTextInputFormatter(9),
    ];
  }
}

/// 通用分隔符输入格式化器
/// 用于在文本输入时按照指定规则添加分隔符
class DividerInputFormatter extends TextInputFormatter {
  /// 第一个分割位数
  final int first;

  /// 后续分割位数
  final int rear;

  /// 分割符
  final String pattern;

  /// 构造函数
  ///
  /// @param first 第一个分割位数，默认3
  /// @param rear 后续分割位数，默认4
  /// @param pattern 分割符，默认空格
  DividerInputFormatter({this.first = 3, this.rear = 4, this.pattern = ' '});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    //不含分隔符的文本
    String allTextPure = newValue.text.replaceAll(RegExp(pattern), '');
    //处理后含分隔符的文本
    String allTextDeal = '';
    //光标位置
    int cursorPosition = newValue.selection.baseOffset;

    for (int i = 0; i < allTextPure.length; i++) {
      if ((i == first || (i - first) % rear == 0) && allTextPure[i] != pattern) {
        allTextDeal = '$allTextDeal$pattern';
      }
      allTextDeal += allTextPure[i];
    }

    ///光标在文字最右侧(尾部)的情况,光标始终在最后
    if (cursorPosition >= newValue.text.length) {
      return TextEditingValue(
        text: allTextDeal,
        selection: TextSelection.collapsed(offset: allTextDeal.length),
      );
    }

    ///光标不在文字尾部的情况
    //如果原光标位置变为分割符,则说明左侧增加一位,光标也加一位
    if (allTextDeal.substring(cursorPosition - 1, cursorPosition) == pattern) {
      cursorPosition++;
    }
    return TextEditingValue(
      text: allTextDeal,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// TextEditingValue 相关说明：
/// - int baseOffset：开始的位置
/// - int extentOffset：结束的位置
/// - TextAffinity affinity：光标的位置
/// - bool isDirectional：是否消除了其基础和范围的歧义（不懂可以直接忽略）

/// 银行卡号输入格式化器
/// 格式：每4位添加一个空格，如 1234 1234 1234 1234 123
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    //获取输入的文本（删除了空格）
    String inuptData = newValue.text.replaceAll(RegExp(r'\s'), '');
    //创建字符缓存体
    StringBuffer stringBuffer = StringBuffer();
    //光标位置
    int cursorPosition = newValue.selection.baseOffset;

    for (int i = 0; i < inuptData.length; i++) {
      //获取每一个字符
      stringBuffer.write(inuptData[i]);
      //当前字符的位置
      int index = i + 1;
      //每四个字条中间添加一个空格，最后一位不在考虑范围里
      if (index % 4 == 0 && inuptData.length != index) {
        stringBuffer.write(" ");
      }
    }

    ///光标在文字最右侧(尾部)的情况,光标始终在最后
    if (cursorPosition >= newValue.text.length) {
      return TextEditingValue(
        //当前的文本
        text: stringBuffer.toString(),
        //光标的位置
        selection: TextSelection.collapsed(
          //设置光标的位置在 文本最后
          offset: stringBuffer.toString().length,
        ),
      );
    }

    ///光标不在文字尾部的情况
    //如果原光标位置变为分割符,则说明左侧增加一位,光标也加一位
    if (stringBuffer.toString().substring(cursorPosition - 1, cursorPosition) == " ") {
      cursorPosition++;
    }
    return TextEditingValue(
      text: stringBuffer.toString(),
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
