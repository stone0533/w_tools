/// 数据验证工具类，用于防止注入攻击和验证各种数据格式
class WValidator {
  /// 验证邮箱格式
  ///
  /// @param email 邮箱地址
  /// @return 是否为有效邮箱格式
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// 验证手机号码格式（中国）
  ///
  /// @param phone 手机号码
  /// @return 是否为有效手机号码格式
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 验证密码强度
  ///
  /// @param password 密码
  /// @return 是否为强密码（至少8位，包含大小写字母和数字）
  static bool isValidPassword(String password) {
    // 至少8位，包含大小写字母和数字
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  /// 验证用户名格式
  ///
  /// @param username 用户名
  /// @return 是否为有效用户名格式（3-20位字母、数字、下划线）
  static bool isValidUsername(String username) {
    // 3-20位字母、数字、下划线
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  /// 验证URL格式
  ///
  /// @param url URL地址
  /// @return 是否为有效URL格式
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 验证IP地址格式
  ///
  /// @param ip IP地址
  /// @return 是否为有效IP地址格式
  static bool isValidIp(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  /// 验证身份证号码格式（中国）
  ///
  /// @param idCard 身份证号码
  /// @return 是否为有效身份证号码格式
  static bool isValidIdCard(String idCard) {
    final idCardRegex = RegExp(
      r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$',
    );
    return idCardRegex.hasMatch(idCard);
  }

  /// 验证银行卡号格式
  ///
  /// @param bankCard 银行卡号
  /// @return 是否为有效银行卡号格式
  static bool isValidBankCard(String bankCard) {
    // 16-19位数字
    final bankCardRegex = RegExp(r'^\d{16,19}$');
    if (!bankCardRegex.hasMatch(bankCard)) {
      return false;
    }
    // 验证Luhn算法
    return _luhnCheck(bankCard);
  }

  /// Luhn算法验证
  ///
  /// @param cardNumber 银行卡号
  /// @return 是否通过Luhn算法验证
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool isEven = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      isEven = !isEven;
    }
    return sum % 10 == 0;
  }

  /// 防止SQL注入
  ///
  /// @param input 输入字符串
  /// @return 处理后的字符串
  static String preventSqlInjection(String input) {
    return input
        .replaceAll(RegExp(r"'"), "''")
        .replaceAll(RegExp(r'"'), '\\"')
        .replaceAll(RegExp(r";"), "")
        .replaceAll(RegExp(r"\\"), "\\\\")
        .replaceAll(RegExp(r"\x00"), "")
        .replaceAll(RegExp(r"\n"), "")
        .replaceAll(RegExp(r"\r"), "")
        .replaceAll(RegExp(r"\x1a"), "");
  }

  /// 防止XSS攻击
  ///
  /// @param input 输入字符串
  /// @return 处理后的字符串
  static String preventXss(String input) {
    return input
        .replaceAll(RegExp(r"<script[^>]*>.*?</script>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"<iframe[^>]*>.*?</iframe>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"<object[^>]*>.*?</object>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"<embed[^>]*>.*?</embed>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"<link[^>]*>.*?</link>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"<style[^>]*>.*?</style>", caseSensitive: false, multiLine: true), "")
        .replaceAll(RegExp(r"javascript:"), "")
        .replaceAll(RegExp(r"on\w+=", caseSensitive: false), "")
        .replaceAll(RegExp(r"<[^>]*>", multiLine: true), "");
  }

  /// 验证输入是否为空
  ///
  /// @param input 输入字符串
  /// @return 是否不为空
  static bool isNotEmpty(String input) {
    return input.trim().isNotEmpty;
  }

  /// 验证输入长度
  ///
  /// @param input 输入字符串
  /// @param min 最小长度
  /// @param max 最大长度
  /// @return 长度是否在指定范围内
  static bool isLengthValid(String input, int min, int max) {
    final length = input.trim().length;
    return length >= min && length <= max;
  }

  /// 验证是否为数字
  ///
  /// @param input 输入字符串
  /// @return 是否为数字
  static bool isNumeric(String input) {
    return double.tryParse(input) != null;
  }

  /// 验证是否为整数
  ///
  /// @param input 输入字符串
  /// @return 是否为整数
  static bool isInteger(String input) {
    return int.tryParse(input) != null;
  }

  /// 验证是否为正数
  ///
  /// @param input 输入字符串
  /// @return 是否为正数
  static bool isPositive(String input) {
    final num? value = double.tryParse(input);
    return value != null && value > 0;
  }

  /// 验证是否为非负数
  ///
  /// @param input 输入字符串
  /// @return 是否为非负数
  static bool isNonNegative(String input) {
    final num? value = double.tryParse(input);
    return value != null && value >= 0;
  }

  /// 验证日期格式（YYYY-MM-DD）
  ///
  /// @param date 日期字符串
  /// @return 是否为有效日期格式
  static bool isValidDate(String date) {
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(date)) {
      return false;
    }
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证时间格式（HH:MM:SS）
  ///
  /// @param time 时间字符串
  /// @return 是否为有效时间格式
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// 验证日期时间格式（YYYY-MM-DD HH:MM:SS）
  ///
  /// @param dateTime 日期时间字符串
  /// @return 是否为有效日期时间格式
  static bool isValidDateTime(String dateTime) {
    final dateTimeRegex = RegExp(r'^\d{4}-\d{2}-\d{2} ([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$');
    if (!dateTimeRegex.hasMatch(dateTime)) {
      return false;
    }
    try {
      DateTime.parse(dateTime);
      return true;
    } catch (e) {
      return false;
    }
  }
}
