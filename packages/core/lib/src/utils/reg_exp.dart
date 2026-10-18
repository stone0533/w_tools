import 'validator.dart';

/// 常用正则表达式字符串常量
///
/// 供需要「字符串形式正则」的场景使用（如后端下发校验规则）；
/// 需要直接匹配时请使用 [WRegExp]。
class WRegExpPattern {
  // 纯静态常量类，禁止实例化
  WRegExpPattern._();

  // ---------- 个人信息 ----------

  /// 密码：至少 8 位，且同时包含小写字母、大写字母与数字
  ///
  /// 与 [WValidator.isValidPassword] 同源（引用 `WValidator.passwordPattern`）。
  static const String password = WValidator.passwordPattern;

  /// 邮箱地址（整串匹配，TLD 至少 2 位）
  static const String email = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// 中国大陆手机号（1 开头，第二位 3-9，共 11 位）
  static const String phone = r'^1[3-9]\d{9}$';

  /// 二代身份证号（18 位，末位可为 X/x）
  static const String idCard =
      r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$';

  /// 中文姓名（2-20 个汉字）
  static const String chineseName = r'^[\u4e00-\u9fa5]{2,20}$';

  // ---------- 网络 ----------

  /// 网络 URL（仅 http / https）
  static const String url = r'^https?:\/\/[^\s]+$';

  /// IPv4 地址
  static const String ipv4 = r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$';

  /// MAC 地址（`:` 或 `-` 分隔）
  static const String macAddress = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$';

  // ---------- 数字 ----------

  /// 数字（可带负号与小数部分）
  static const String number = r'^-?\d+(\.\d+)?$';

  /// 整数（可带负号）
  static const String integer = r'^-?\d+$';

  /// 正数（可带小数部分，不含 0）
  static const String positiveNumber = r'^(?!0+(\.0+)?$)\d+(\.\d+)?$';

  /// 正整数（不含 0）
  static const String positiveInteger = r'^(?!0+$)\d+$';

  /// 小数（可带负号，必须有小数部分）
  static const String decimal = r'^-?\d+\.\d+$';

  /// 正小数（必须有小数部分，不含 0）
  static const String positiveDecimal = r'^(?!0+\.0+$)\d+\.\d+$';

  // ---------- 其他 ----------

  /// 日期格式（YYYY-MM-DD，仅校验格式；真实日期请用 [WValidator.isValidDate]）
  static const String date = r'^\d{4}-\d{2}-\d{2}$';

  /// 银行卡号（16-19 位数字，仅校验位数）
  static const String bankCard = r'^\d{16,19}$';

  /// 邮政编码（6 位数字）
  static const String postalCode = r'^\d{6}$';
}

/// 按分类组织的正则表达式字符串
///
/// 便于按类别遍历或批量下发校验规则；键名与 [WRegExpPattern] 字段同名。
class WRegExpPreset {
  // 纯静态常量类，禁止实例化
  WRegExpPreset._();

  /// 个人信息相关
  static const Map<String, String> personal = {
    'password': WRegExpPattern.password,
    'email': WRegExpPattern.email,
    'phone': WRegExpPattern.phone,
    'idCard': WRegExpPattern.idCard,
    'chineseName': WRegExpPattern.chineseName,
  };

  /// 网络相关
  static const Map<String, String> network = {
    'url': WRegExpPattern.url,
    'ipv4': WRegExpPattern.ipv4,
    'macAddress': WRegExpPattern.macAddress,
  };

  /// 数字相关
  static const Map<String, String> number = {
    'number': WRegExpPattern.number,
    'integer': WRegExpPattern.integer,
    'positiveNumber': WRegExpPattern.positiveNumber,
    'positiveInteger': WRegExpPattern.positiveInteger,
    'decimal': WRegExpPattern.decimal,
    'positiveDecimal': WRegExpPattern.positiveDecimal,
  };

  /// 其他
  static const Map<String, String> misc = {
    'date': WRegExpPattern.date,
    'bankCard': WRegExpPattern.bankCard,
    'postalCode': WRegExpPattern.postalCode,
  };
}

/// 常用正则表达式与匹配 / 提取 / 格式化工具
///
/// 本类只提供正则模式与基于模式的文本处理；业务校验（邮箱、密码强度、
/// 银行卡 Luhn、真实日期等）请统一使用 [WValidator]。
class WRegExp {
  // 纯静态工具类，禁止实例化
  WRegExp._();

  // ---------- 个人信息 ----------

  /// 密码正则
  static final RegExp password = RegExp(WRegExpPattern.password);

  /// 邮箱地址正则
  static final RegExp email = RegExp(WRegExpPattern.email);

  /// 手机号正则
  static final RegExp phone = RegExp(WRegExpPattern.phone);

  /// 身份证号正则
  static final RegExp idCard = RegExp(WRegExpPattern.idCard);

  /// 中文姓名正则
  static final RegExp chineseName = RegExp(WRegExpPattern.chineseName);

  // ---------- 网络 ----------

  /// 网络 URL 正则
  static final RegExp url = RegExp(WRegExpPattern.url);

  /// IPv4 地址正则
  static final RegExp ipv4 = RegExp(WRegExpPattern.ipv4);

  /// MAC 地址正则
  static final RegExp macAddress = RegExp(WRegExpPattern.macAddress);

  // ---------- 数字 ----------

  /// 数字正则
  static final RegExp number = RegExp(WRegExpPattern.number);

  /// 整数正则
  static final RegExp integer = RegExp(WRegExpPattern.integer);

  /// 正数正则
  static final RegExp positiveNumber = RegExp(WRegExpPattern.positiveNumber);

  /// 正整数正则
  static final RegExp positiveInteger = RegExp(WRegExpPattern.positiveInteger);

  /// 小数正则
  static final RegExp decimal = RegExp(WRegExpPattern.decimal);

  /// 正小数正则
  static final RegExp positiveDecimal = RegExp(WRegExpPattern.positiveDecimal);

  // ---------- 其他 ----------

  /// 日期格式正则
  static final RegExp date = RegExp(WRegExpPattern.date);

  /// 银行卡号正则
  static final RegExp bankCard = RegExp(WRegExpPattern.bankCard);

  /// 邮政编码正则
  static final RegExp postalCode = RegExp(WRegExpPattern.postalCode);

  // ---------- 匹配结果 ----------

  /// 密码的首次匹配结果，无匹配时为 null
  static Match? firstPasswordMatch(String input) {
    return password.firstMatch(input);
  }

  /// 邮箱地址的首次匹配结果，无匹配时为 null
  static Match? firstEmailMatch(String input) {
    return email.firstMatch(input);
  }

  /// 手机号的首次匹配结果，无匹配时为 null
  static Match? firstPhoneMatch(String input) {
    return phone.firstMatch(input);
  }

  /// 身份证号的首次匹配结果，无匹配时为 null
  static Match? firstIdCardMatch(String input) {
    return idCard.firstMatch(input);
  }

  /// URL 的首次匹配结果，无匹配时为 null
  static Match? firstUrlMatch(String input) {
    return url.firstMatch(input);
  }

  /// 日期的首次匹配结果，无匹配时为 null
  ///
  /// 仅匹配 `YYYY-MM-DD` 格式，不代表日期真实存在；语义校验请用
  /// [WValidator.isValidDate]。
  static Match? firstDateMatch(String input) {
    return date.firstMatch(input);
  }

  /// 银行卡号的首次匹配结果，无匹配时为 null
  static Match? firstBankCardMatch(String input) {
    return bankCard.firstMatch(input);
  }

  /// 邮政编码的首次匹配结果，无匹配时为 null
  static Match? firstPostalCodeMatch(String input) {
    return postalCode.firstMatch(input);
  }

  /// IPv4 地址的首次匹配结果，无匹配时为 null
  static Match? firstIpv4Match(String input) {
    return ipv4.firstMatch(input);
  }

  /// MAC 地址的首次匹配结果，无匹配时为 null
  static Match? firstMacAddressMatch(String input) {
    return macAddress.firstMatch(input);
  }

  /// 中文姓名的首次匹配结果，无匹配时为 null
  static Match? firstChineseNameMatch(String input) {
    return chineseName.firstMatch(input);
  }

  /// 数字的首次匹配结果，无匹配时为 null
  static Match? firstNumberMatch(String input) {
    return number.firstMatch(input);
  }

  /// 整数的首次匹配结果，无匹配时为 null
  static Match? firstIntegerMatch(String input) {
    return integer.firstMatch(input);
  }

  /// 正数的首次匹配结果，无匹配时为 null
  static Match? firstPositiveNumberMatch(String input) {
    return positiveNumber.firstMatch(input);
  }

  /// 正整数的首次匹配结果，无匹配时为 null
  static Match? firstPositiveIntegerMatch(String input) {
    return positiveInteger.firstMatch(input);
  }

  /// 小数的首次匹配结果，无匹配时为 null
  static Match? firstDecimalMatch(String input) {
    return decimal.firstMatch(input);
  }

  /// 正小数的首次匹配结果，无匹配时为 null
  static Match? firstPositiveDecimalMatch(String input) {
    return positiveDecimal.firstMatch(input);
  }

  // ---------- 提取 / 掩码 / 格式化 ----------

  /// 从身份证号中提取出生日期
  ///
  /// 返回 `YYYY-MM-DD`；身份证号非法或出生日期不存在时返回 null。
  static String? extractBirthdayFromIdCard(String idCard) {
    final match = WRegExp.idCard.firstMatch(idCard);
    if (match == null || idCard.length < 14) {
      return null;
    }

    // 提取出生日期部分 (yyyyMMdd)
    final birthdayPart = idCard.substring(6, 14);
    final birthday =
        '${birthdayPart.substring(0, 4)}-${birthdayPart.substring(4, 6)}-${birthdayPart.substring(6, 8)}';
    // 身份证正则只约束月/日的数字范围，这里再排除 2 月 30 日等非法日期
    return WValidator.isValidDate(birthday) ? birthday : null;
  }

  /// 从身份证号中提取性别
  ///
  /// 返回「男」或「女」；身份证号非法时返回 null。
  static String? extractGenderFromIdCard(String idCard) {
    final match = WRegExp.idCard.firstMatch(idCard);
    if (match != null && idCard.length >= 17) {
      // 提取性别码（第 17 位）
      final genderCodeStr = idCard[16];
      final genderCode = int.tryParse(genderCodeStr);
      if (genderCode != null) {
        return genderCode % 2 == 1 ? "男" : "女";
      }
    }
    return null;
  }

  /// 手机号掩码处理，格式为 `XXX****XXXX`
  ///
  /// 手机号格式不合法时原样返回。
  static String maskPhone(String phone) {
    if (WRegExp.phone.hasMatch(phone)) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  /// 银行卡号掩码处理，仅保留前 4 位与后 4 位
  ///
  /// 卡号格式不合法或长度不足时原样返回。
  static String maskBankCard(String bankCard) {
    if (WRegExp.bankCard.hasMatch(bankCard)) {
      final length = bankCard.length;
      if (length <= 8) {
        return bankCard;
      }
      final prefix = bankCard.substring(0, 4);
      final suffix = bankCard.substring(length - 4);
      final stars = '*' * (length - 8);
      return '$prefix$stars$suffix';
    }
    return bankCard;
  }

  /// 格式化手机号，格式为 `XXX-XXXX-XXXX`
  ///
  /// 手机号格式不合法时原样返回。
  static String formatPhone(String phone) {
    if (WRegExp.phone.hasMatch(phone)) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  /// 将 `YYYYMMDD` 格式化为 `YYYY-MM-DD`
  ///
  /// 输入格式不合法或日期不存在时返回 null。
  static String? formatDate(String date) {
    if (date.length == 8) {
      final match = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(date);
      if (match != null) {
        final formatted = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
        // 与 WValidator.isValidDate 保持一致，拒绝 20241399 这类非法日期
        return WValidator.isValidDate(formatted) ? formatted : null;
      }
    }
    return null;
  }
}
