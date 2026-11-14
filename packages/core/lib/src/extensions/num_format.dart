/// 数字格式化：千分位 / 货币 / 百分比 / 前导零。
///
/// 12.0 起从 `w_tools_ui` 迁到 `w_tools_core`：格式化与 UI 无关，
/// 需要 locale 感知时直接用 `intl`。
/// num 格式化扩展：千分位 / 货币 / 百分比 / 前导零
extension WNumFormatExtension on num {
  /// 转换为带千分位分隔符的字符串
  ///
  /// 科学计数法（如 `1e+21`、`1.5e-7`）会先展开为普通十进制再分组；
  /// `NaN` / `Infinity` 原样返回。
  String get toThousandsSeparated {
    final str = _expandScientificNotation(toString());
    if (str == 'NaN' || str == 'Infinity' || str == '-Infinity') {
      return str;
    }

    String group(String integerPart) {
      return integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m.group(1)},',
      );
    }

    final dotIndex = str.indexOf('.');
    if (dotIndex == -1) {
      return group(str);
    }
    return '${group(str.substring(0, dotIndex))}${str.substring(dotIndex)}';
  }

  /// 转换为带货币符号的字符串
  ///
  /// 科学计数法（如 `1e+21`、`1.5e-7`）会先展开为普通十进制再分组；
  /// `NaN` / `Infinity` 原样返回（不添加符号）。
  String toCurrency({
    String symbol = '',
    String thousandSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final str = _expandScientificNotation(toString());
    if (str == 'NaN' || str == 'Infinity' || str == '-Infinity') {
      return str;
    }

    final negative = str.startsWith('-');
    final body = negative ? str.substring(1) : str;

    String group(String integerPart) {
      return integerPart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m.group(1)}$thousandSeparator',
      );
    }

    final dotIndex = body.indexOf('.');
    final formatted = dotIndex == -1
        ? group(body)
        : '${group(body.substring(0, dotIndex))}'
              '$decimalSeparator${body.substring(dotIndex + 1)}';

    return '${negative ? '-' : ''}$symbol$formatted';
  }

  /// 转换为百分比格式的字符串；整数结果不带 `.0`。
  String get toPercent {
    final value = this * 100;
    if (value.isNaN || value.isInfinite) {
      return '$value%';
    }
    if (value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }
    final text = value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$text%';
  }

  /// 转换为百分比格式的字符串（保留指定小数位数）
  String toPercentWithFixed(int fractionDigits) =>
      '${(this * 100).toStringAsFixed(fractionDigits)}%';

  /// 将数字转换为带前导零的字符串；负数保留符号并计入总长度。
  String toPadLeft(int length) {
    assert(length >= 0, 'length 不能为负');
    final negative = this < 0;
    final digits = abs().toString();
    final target = length - (negative ? 1 : 0);
    final padded = target > digits.length ? digits.padLeft(target, '0') : digits;
    return negative ? '-$padded' : padded;
  }
}

/// 将科学计数法字符串展开为普通十进制字符串
///
/// 例如 `1e+21` → `1000000000000000000000`，`1.5e-7` → `0.00000015`；
/// 非科学计数法字符串原样返回。
String _expandScientificNotation(String value) {
  final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?[eE]([+-]?\d+)$').firstMatch(value);
  if (match == null) {
    return value;
  }

  final sign = match.group(1) ?? '';
  final integerDigits = match.group(2)!;
  final fractionDigits = match.group(3) ?? '';
  final exponent = int.parse(match.group(4)!);

  final digits = '$integerDigits$fractionDigits';
  final decimalPosition = integerDigits.length + exponent;

  if (decimalPosition <= 0) {
    final zeros = '0' * -decimalPosition;
    return '${sign}0.$zeros$digits';
  }
  if (decimalPosition >= digits.length) {
    final zeros = '0' * (decimalPosition - digits.length);
    return '$sign$digits$zeros';
  }
  return '$sign${digits.substring(0, decimalPosition)}.${digits.substring(decimalPosition)}';
}
