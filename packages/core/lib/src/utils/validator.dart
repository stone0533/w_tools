/// 数据校验工具类
///
/// 提供常见格式校验（邮箱、手机号、身份证、银行卡等）与基础字符清洗。
/// 纯正则格式匹配 / 提取 / 格式化请使用 [WRegExp]；本类负责业务语义校验
/// （如密码强度、银行卡 Luhn、真实日期）。
///
/// 注意：`escapeSql` / `stripHtml` 只做基础字符替换，
/// 不能替代参数化查询与 HTML 转义，不应作为唯一的安全防线。
class WValidator {
  // 纯静态工具类，禁止实例化
  WValidator._();

  /// 是否为有效邮箱地址
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// 是否为中国大陆手机号
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 密码规则的唯一真相
  ///
  /// 规则：至少 8 位，且同时包含小写字母、大写字母与数字（允许符号）。
  /// [WRegExpPattern.password] 直接引用本常量，两个公开入口不会再各写一套。
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$';

  /// 是否为强密码
  ///
  /// 规则：至少 8 位，且同时包含小写字母、大写字母与数字。
  /// 规则定义见 [passwordPattern]。
  static bool isValidPassword(String password) {
    return RegExp(passwordPattern).hasMatch(password);
  }

  /// 是否为有效用户名
  ///
  /// 规则：3-20 位字母、数字或下划线。
  static bool isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  /// 是否为有效的网络 URL（仅 http / https）
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 是否为有效 IPv4 地址
  static bool isValidIpv4(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  /// 是否为有效身份证号
  ///
  /// 仅校验 18 位格式与出生年月日的数字范围，不校验真实日期与校验位。
  static bool isValidIdCard(String idCard) {
    final idCardRegex = RegExp(
      r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$',
    );
    return idCardRegex.hasMatch(idCard);
  }

  /// 是否为有效银行卡号
  ///
  /// 先校验 16-19 位数字，再通过 Luhn 算法校验。
  static bool isValidBankCard(String bankCard) {
    final bankCardRegex = RegExp(r'^\d{16,19}$');
    if (!bankCardRegex.hasMatch(bankCard)) {
      return false;
    }
    return _luhnCheck(bankCard);
  }

  /// Luhn 算法校验银行卡号
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

  /// 对输入做基础的 SQL 注入字符清洗
  ///
  /// 仅做转义与危险字符移除，不能替代参数化查询。
  static String escapeSql(String input) {
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

  /// 对输入做基础的 XSS 字符清洗
  ///
  /// 移除常见标签与事件属性，不能替代输出侧的 HTML 转义。
  static String stripHtml(String input) {
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

  /// 去除首尾空白后是否非空
  static bool isNotBlank(String input) {
    return input.trim().isNotEmpty;
  }

  /// 去除首尾空白后的长度是否在 [min] 与 [max] 之间（含边界）
  static bool isLengthValid(String input, int min, int max) {
    final length = input.trim().length;
    return length >= min && length <= max;
  }

  /// 是否为有限数字（允许科学计数法，拒绝 `NaN` / `Infinity`）
  static bool isNumeric(String input) {
    final value = double.tryParse(input);
    return value != null && value.isFinite;
  }

  /// 是否为整数（使用 `int.tryParse`）
  static bool isInteger(String input) {
    return int.tryParse(input) != null;
  }

  /// 是否为正数（大于 0 的有限数字）
  static bool isPositive(String input) {
    final num? value = double.tryParse(input);
    return value != null && value.isFinite && value > 0;
  }

  /// 是否为非负的有限数字（大于等于 0）
  static bool isNonNegative(String input) {
    final num? value = double.tryParse(input);
    return value != null && value.isFinite && value >= 0;
  }

  /// 是否为有效中文姓名（2-20 个汉字）
  static bool isValidChineseName(String input) {
    return RegExp(r'^[\u4e00-\u9fa5]{2,20}$').hasMatch(input);
  }

  /// 是否为正整数（大于 0）
  static bool isValidPositiveInteger(String input) {
    final value = int.tryParse(input);
    return value != null && value > 0;
  }

  /// 是否为小数（必须包含小数部分，可带负号）
  static bool isValidDecimal(String input) {
    return RegExp(r'^-?\d+\.\d+$').hasMatch(input);
  }

  /// 是否为正小数（必须包含小数部分且大于 0）
  static bool isValidPositiveDecimal(String input) {
    if (!isValidDecimal(input)) {
      return false;
    }
    final value = double.tryParse(input);
    return value != null && value > 0;
  }

  /// 是否为有效邮政编码（6 位数字）
  static bool isValidPostalCode(String input) {
    return RegExp(r'^\d{6}$').hasMatch(input);
  }

  /// 是否为有效 MAC 地址（`:` 或 `-` 分隔）
  static bool isValidMacAddress(String input) {
    return RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(input);
  }

  /// 是否为有效日期（YYYY-MM-DD）
  ///
  /// 除格式外还会校验真实日期范围，例如 `2023-02-30`、`2023-13-01`
  /// 都会返回 false。
  static bool isValidDate(String date) {
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(date)) {
      return false;
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) {
      return false;
    }
    // DateTime.parse 会把越界值归一化（如 2023-02-30 → 2023-03-02），
    // 因此需要按字段回校，确保解析结果与原字符串一致。
    final parts = date.split('-');
    return parsed.year == int.parse(parts[0]) &&
        parsed.month == int.parse(parts[1]) &&
        parsed.day == int.parse(parts[2]);
  }

  /// 是否为有效时间（`H:MM:SS` 或 `HH:MM:SS`，24 小时制）
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// 是否为有效日期时间（`YYYY-MM-DD H:MM:SS` 或 `YYYY-MM-DD HH:MM:SS`）
  ///
  /// 日期部分会做真实日期校验，时间部分由正则限定在合法范围内。
  static bool isValidDateTime(String dateTime) {
    final dateTimeRegex = RegExp(r'^\d{4}-\d{2}-\d{2} ([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$');
    if (!dateTimeRegex.hasMatch(dateTime)) {
      return false;
    }
    return isValidDate(dateTime.split(' ').first);
  }
}
