/// 子包版本约束。必须与仓库 `packages/*/pubspec.yaml` 的当前版本一致，
/// 由 `test/init_test.dart` 读取仓库 pubspec 校验（防止版本漂移）。
const subpackageConstraints = <String, String>{
  'w_tools_core': '^3.1.1',
  'w_tools_async': '^6.1.0',
  'w_tools_app': '^3.1.0',
  'w_tools_app_getx': '^2.1.0',
  'w_tools_form': '^6.0.0',
  'w_tools_ui': '^8.0.0',
  'w_tools_api': '^5.1.0',
  'w_tools_toast': '^2.1.0',
  'w_tools_qr': '^2.0.0',
  'w_tools_map': '^3.0.0',
  'w_tools_map_google': '^2.0.0',
};

/// CLI 自己的版本约束（消费方放在 dev_dependencies）
const cliConstraint = '^1.16.0';

/// 设备验证工具（dev_dependencies，独立包）
const wToolsDeviceConstraint = '^0.3.0';
