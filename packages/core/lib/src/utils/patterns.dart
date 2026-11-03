/// 正则字符串的唯一来源（包内使用，不导出）。
///
/// `WRegExp`（预编译 RegExp）与已弃用的 `WRegExpPattern` / `WRegExpPreset` 都从这里
/// 取字符串，避免同一规则写三份。
library;

const String kPasswordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$';
const String kEmailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
const String kPhonePattern = r'^1[3-9]\d{9}$';
const String kUsernamePattern = r'^[a-zA-Z0-9_]{3,20}$';
const String kIdCardPattern =
    r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$';
const String kChineseNamePattern = r'^[\u4e00-\u9fa5]{2,20}$';
const String kUrlPattern = r'^https?:\/\/[^\s]+$';
const String kIpv4Pattern = r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$';
const String kMacAddressPattern = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$';
const String kNumberPattern = r'^-?\d+(\.\d+)?$';
const String kIntegerPattern = r'^-?\d+$';
const String kPositiveNumberPattern = r'^(?!0+(\.0+)?$)\d+(\.\d+)?$';
const String kPositiveIntegerPattern = r'^(?!0+$)\d+$';
const String kDecimalPattern = r'^-?\d+\.\d+$';
const String kPositiveDecimalPattern = r'^(?!0+\.0+$)\d+\.\d+$';
const String kDatePattern = r'^\d{4}-\d{2}-\d{2}$';
const String kBankCardPattern = r'^\d{16,19}$';
const String kPostalCodePattern = r'^\d{6}$';
