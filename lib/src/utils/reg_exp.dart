// 正则表达式字符串常量类
class WRegExpStr {
  // 个人信息相关
  static const String password = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$';
  static const String email =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  static const String phone = r'^1[3-9]\d{9}$';
  static const String idCard =
      r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$';
  static const String chineseName = r'^[\u4e00-\u9fa5]{2,20}$';

  // 网络相关
  static const String url = r'^https?:\/\/[^\s]+$';
  static const String ipV4 = r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$';
  static const String macAddress = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$';

  // 数字相关
  static const String number = r'^-?\d+(\.\d+)?$';
  static const String integer = r'^-?\d+$';
  static const String positiveNumber = r'^\d+(\.\d+)?$';
  static const String positiveInteger = r'^\d+$';
  static const String decimal = r'^-?\d+\.\d+$';
  static const String positiveDecimal = r'^\d+\.\d+$';

  // 其他
  static const String date = r'^\d{4}-\d{2}-\d{2}$';
  static const String bankCard = r'^\d{16,19}$';
  static const String postalCode = r'^\d{6}$';
}

// 正则表达式分类常量
class WRegExpCategory {
  // 个人信息相关
  static const Map<String, String> personal = {
    'password': WRegExpStr.password,
    'email': WRegExpStr.email,
    'phone': WRegExpStr.phone,
    'idCard': WRegExpStr.idCard,
    'chineseName': WRegExpStr.chineseName,
  };

  // 网络相关
  static const Map<String, String> network = {
    'url': WRegExpStr.url,
    'ipV4': WRegExpStr.ipV4,
    'macAddress': WRegExpStr.macAddress,
  };

  // 数字相关
  static const Map<String, String> number = {
    'number': WRegExpStr.number,
    'integer': WRegExpStr.integer,
    'positiveNumber': WRegExpStr.positiveNumber,
    'positiveInteger': WRegExpStr.positiveInteger,
    'decimal': WRegExpStr.decimal,
    'positiveDecimal': WRegExpStr.positiveDecimal,
  };

  // 其他
  static const Map<String, String> other = {
    'date': WRegExpStr.date,
    'bankCard': WRegExpStr.bankCard,
    'postalCode': WRegExpStr.postalCode,
  };
}

class WRegExp {
  // 个人信息相关
  // 密码正则表达式
  static final RegExp password = RegExp(WRegExpStr.password);

  // 電郵地址正则表达式
  static final RegExp email = RegExp(WRegExpStr.email);

  // 手机号正则表达式
  static final RegExp phone = RegExp(WRegExpStr.phone);

  // 身份证号正则表达式
  static final RegExp idCard = RegExp(WRegExpStr.idCard);

  // 中文姓名正则表达式
  static final RegExp chineseName = RegExp(WRegExpStr.chineseName);

  // 网络相关
  // URL正则表达式
  static final RegExp url = RegExp(WRegExpStr.url);

  // IP地址正则表达式
  static final RegExp ipV4 = RegExp(WRegExpStr.ipV4);

  // MAC地址正则表达式
  static final RegExp macAddress = RegExp(WRegExpStr.macAddress);

  // 数字相关
  // 数字正则表达式
  static final RegExp number = RegExp(WRegExpStr.number);

  // 整数正则表达式
  static final RegExp integer = RegExp(WRegExpStr.integer);

  // 正数正则表达式
  static final RegExp positiveNumber = RegExp(WRegExpStr.positiveNumber);

  // 正整数正则表达式
  static final RegExp positiveInteger = RegExp(WRegExpStr.positiveInteger);

  // 小数正则表达式
  static final RegExp decimal = RegExp(WRegExpStr.decimal);

  // 正小数正则表达式
  static final RegExp positiveDecimal = RegExp(WRegExpStr.positiveDecimal);

  // 其他
  // 日期格式正则表达式
  static final RegExp date = RegExp(WRegExpStr.date);

  // 银行卡号正则表达式
  static final RegExp bankCard = RegExp(WRegExpStr.bankCard);

  // 邮政编码正则表达式
  static final RegExp postalCode = RegExp(WRegExpStr.postalCode);

  // 验证密码
  static bool validatePassword(String input) {
    return password.hasMatch(input);
  }

  // 验证電郵地址
  static bool validateEmail(String input) {
    return email.hasMatch(input);
  }

  // 验证手机号
  static bool validatePhone(String input) {
    return phone.hasMatch(input);
  }

  // 验证身份证号
  static bool validateIdCard(String input) {
    return idCard.hasMatch(input);
  }

  // 验证URL
  static bool validateUrl(String input) {
    return url.hasMatch(input);
  }

  // 验证日期格式
  static bool validateDate(String input) {
    return date.hasMatch(input);
  }

  // 验证银行卡号
  static bool validateBankCard(String input) {
    return bankCard.hasMatch(input);
  }

  // 验证邮政编码
  static bool validatePostalCode(String input) {
    return postalCode.hasMatch(input);
  }

  // 验证IP地址
  static bool validateIpV4(String input) {
    return ipV4.hasMatch(input);
  }

  // 验证MAC地址
  static bool validateMacAddress(String input) {
    return macAddress.hasMatch(input);
  }

  // 验证中文姓名
  static bool validateChineseName(String input) {
    return chineseName.hasMatch(input);
  }

  // 验证数字
  static bool validateNumber(String input) {
    return number.hasMatch(input);
  }

  // 验证整数
  static bool validateInteger(String input) {
    return integer.hasMatch(input);
  }

  // 验证正数
  static bool validatePositiveNumber(String input) {
    return positiveNumber.hasMatch(input);
  }

  // 验证正整数
  static bool validatePositiveInteger(String input) {
    return positiveInteger.hasMatch(input);
  }

  // 验证小数
  static bool validateDecimal(String input) {
    return decimal.hasMatch(input);
  }

  // 验证正小数
  static bool validatePositiveDecimal(String input) {
    return positiveDecimal.hasMatch(input);
  }

  // 获取密码匹配结果
  static Match? getPasswordMatch(String input) {
    return password.firstMatch(input);
  }

  // 获取電郵地址匹配结果
  static Match? getEmailMatch(String input) {
    return email.firstMatch(input);
  }

  // 获取手机号匹配结果
  static Match? getPhoneMatch(String input) {
    return phone.firstMatch(input);
  }

  // 获取身份证号匹配结果
  static Match? getIdCardMatch(String input) {
    return idCard.firstMatch(input);
  }

  // 获取URL匹配结果
  static Match? getUrlMatch(String input) {
    return url.firstMatch(input);
  }

  // 获取日期格式匹配结果
  static Match? getDateMatch(String input) {
    return date.firstMatch(input);
  }

  // 获取银行卡号匹配结果
  static Match? getBankCardMatch(String input) {
    return bankCard.firstMatch(input);
  }

  // 获取邮政编码匹配结果
  static Match? getPostalCodeMatch(String input) {
    return postalCode.firstMatch(input);
  }

  // 获取IP地址匹配结果
  static Match? getIpV4Match(String input) {
    return ipV4.firstMatch(input);
  }

  // 获取MAC地址匹配结果
  static Match? getMacAddressMatch(String input) {
    return macAddress.firstMatch(input);
  }

  // 获取中文姓名匹配结果
  static Match? getChineseNameMatch(String input) {
    return chineseName.firstMatch(input);
  }

  // 获取数字匹配结果
  static Match? getNumberMatch(String input) {
    return number.firstMatch(input);
  }

  // 获取整数匹配结果
  static Match? getIntegerMatch(String input) {
    return integer.firstMatch(input);
  }

  // 获取正数匹配结果
  static Match? getPositiveNumberMatch(String input) {
    return positiveNumber.firstMatch(input);
  }

  // 获取正整数匹配结果
  static Match? getPositiveIntegerMatch(String input) {
    return positiveInteger.firstMatch(input);
  }

  // 获取小数匹配结果
  static Match? getDecimalMatch(String input) {
    return decimal.firstMatch(input);
  }

  // 获取正小数匹配结果
  static Match? getPositiveDecimalMatch(String input) {
    return positiveDecimal.firstMatch(input);
  }

  // 从身份证号中提取出生日期
  ///
  /// @param idCard 身份证号
  /// @return 出生日期字符串，格式为 YYYY-MM-DD，如果提取失败返回 null
  static String? extractBirthdayFromIdCard(String idCard) {
    final match = WRegExp.idCard.firstMatch(idCard);
    if (match != null && idCard.length >= 14) {
      // 提取出生日期部分 (yyyyMMdd)
      final birthdayPart = idCard.substring(6, 14);
      // 格式化为 yyyy-MM-dd
      return '${birthdayPart.substring(0, 4)}-${birthdayPart.substring(4, 6)}-${birthdayPart.substring(6, 8)}';
    }
    return null;
  }

  // 从身份证号中提取性别
  ///
  /// @param idCard 身份证号
  /// @return 性别字符串，"男" 或 "女"，如果提取失败返回 null
  static String? extractGenderFromIdCard(String idCard) {
    final match = WRegExp.idCard.firstMatch(idCard);
    if (match != null && idCard.length >= 17) {
      // 提取性别码（第17位）
      final genderCodeStr = idCard[16];
      final genderCode = int.tryParse(genderCodeStr);
      if (genderCode != null) {
        return genderCode % 2 == 1 ? "男" : "女";
      }
    }
    return null;
  }

  // 手机号掩码处理
  ///
  /// @param phone 手机号
  /// @return 掩码处理后的手机号，格式为 "XXX****XXXX"
  static String maskPhone(String phone) {
    if (validatePhone(phone)) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  // 银行卡号掩码处理
  ///
  /// @param bankCard 银行卡号
  /// @return 掩码处理后的银行卡号，只保留前4位和后4位
  static String maskBankCard(String bankCard) {
    if (validateBankCard(bankCard)) {
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

  // 格式化手机号
  ///
  /// @param phone 手机号
  /// @return 格式化后的手机号，格式为 "XXX-XXXX-XXXX"
  static String formatPhone(String phone) {
    if (validatePhone(phone)) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  // 格式化日期
  ///
  /// @param date 日期字符串，格式为 YYYYMMDD
  /// @return 格式化后的日期字符串，格式为 YYYY-MM-DD
  static String? formatDate(String date) {
    if (date.length == 8) {
      final match = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(date);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
    }
    return null;
  }
}

/// String 扩展，提供正则表达式验证方法
extension WRegExpStringExtension on String {
  // 验证密码
  bool get isPasswordValid => WRegExp.validatePassword(this);

  // 验证電郵地址
  bool get isEmailValid => WRegExp.validateEmail(this);

  // 验证手机号
  bool get isPhoneValid => WRegExp.validatePhone(this);

  // 验证身份证号
  bool get isIdCardValid => WRegExp.validateIdCard(this);

  // 验证URL
  bool get isUrlValid => WRegExp.validateUrl(this);

  // 验证日期格式
  bool get isDateValid => WRegExp.validateDate(this);

  // 验证银行卡号
  bool get isBankCardValid => WRegExp.validateBankCard(this);

  // 验证邮政编码
  bool get isPostalCodeValid => WRegExp.validatePostalCode(this);

  // 验证IP地址
  bool get isIpV4Valid => WRegExp.validateIpV4(this);

  // 验证MAC地址
  bool get isMacAddressValid => WRegExp.validateMacAddress(this);

  // 验证中文姓名
  bool get isChineseNameValid => WRegExp.validateChineseName(this);

  // 验证数字
  bool get isNumberValid => WRegExp.validateNumber(this);

  // 验证整数
  bool get isIntegerValid => WRegExp.validateInteger(this);

  // 验证正数
  bool get isPositiveNumberValid => WRegExp.validatePositiveNumber(this);

  // 验证正整数
  bool get isPositiveIntegerValid => WRegExp.validatePositiveInteger(this);

  // 验证小数
  bool get isDecimalValid => WRegExp.validateDecimal(this);

  // 验证正小数
  bool get isPositiveDecimalValid => WRegExp.validatePositiveDecimal(this);

  // 获取密码匹配结果
  Match? get passwordMatch => WRegExp.getPasswordMatch(this);

  // 获取電郵地址匹配结果
  Match? get emailMatch => WRegExp.getEmailMatch(this);

  // 获取手机号匹配结果
  Match? get phoneMatch => WRegExp.getPhoneMatch(this);

  // 获取身份证号匹配结果
  Match? get idCardMatch => WRegExp.getIdCardMatch(this);

  // 获取URL匹配结果
  Match? get urlMatch => WRegExp.getUrlMatch(this);

  // 获取日期格式匹配结果
  Match? get dateMatch => WRegExp.getDateMatch(this);

  // 获取银行卡号匹配结果
  Match? get bankCardMatch => WRegExp.getBankCardMatch(this);

  // 获取邮政编码匹配结果
  Match? get postalCodeMatch => WRegExp.getPostalCodeMatch(this);

  // 获取IP地址匹配结果
  Match? get ipV4Match => WRegExp.getIpV4Match(this);

  // 获取MAC地址匹配结果
  Match? get macAddressMatch => WRegExp.getMacAddressMatch(this);

  // 获取中文姓名匹配结果
  Match? get chineseNameMatch => WRegExp.getChineseNameMatch(this);

  // 获取数字匹配结果
  Match? get numberMatch => WRegExp.getNumberMatch(this);

  // 获取整数匹配结果
  Match? get integerMatch => WRegExp.getIntegerMatch(this);

  // 获取正数匹配结果
  Match? get positiveNumberMatch => WRegExp.getPositiveNumberMatch(this);

  // 获取正整数匹配结果
  Match? get positiveIntegerMatch => WRegExp.getPositiveIntegerMatch(this);

  // 获取小数匹配结果
  Match? get decimalMatch => WRegExp.getDecimalMatch(this);

  // 获取正小数匹配结果
  Match? get positiveDecimalMatch => WRegExp.getPositiveDecimalMatch(this);

  // 从身份证号中提取出生日期
  String? get birthdayFromIdCard => WRegExp.extractBirthdayFromIdCard(this);

  // 从身份证号中提取性别
  String? get genderFromIdCard => WRegExp.extractGenderFromIdCard(this);

  // 手机号掩码处理
  String get maskedPhone => WRegExp.maskPhone(this);

  // 银行卡号掩码处理
  String get maskedBankCard => WRegExp.maskBankCard(this);

  // 格式化手机号
  String get formattedPhone => WRegExp.formatPhone(this);

  // 格式化日期
  String? get formattedDate => WRegExp.formatDate(this);
}
