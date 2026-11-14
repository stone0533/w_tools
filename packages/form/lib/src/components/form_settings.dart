import 'validation/validator.dart';

/// 包内：`WForm` 注入的默认校验设置（按 controller 存储）。
///
/// `WFormController.validatorSettings` 只保留只读 getter；写入口只有
/// `WForm(validatorSettings:)`，避免业务在运行期覆盖成第二份来源。
final Expando<WFormValidatorSettings> _settings = Expando<WFormValidatorSettings>();

/// 读取 controller 上由 `WForm` 注入的默认校验设置。
WFormValidatorSettings? formValidatorSettingsOf(Object controller) => _settings[controller];

/// 写入 / 清除 controller 上由 `WForm` 注入的默认校验设置。
void setFormValidatorSettings(Object controller, WFormValidatorSettings? settings) {
  _settings[controller] = settings;
}
