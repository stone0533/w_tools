import 'border_registry.dart';

/// 包内访问某个 `WFormController` 的边框错误通道。
///
/// 不导出：业务侧只用 `WFormController.setError` / `clearError`。
/// 用 `Expando` 保存，避免把 `WFormBorderRegistry` 放进 controller 的公开成员。
final Expando<WFormBorderRegistry> _registries = Expando<WFormBorderRegistry>();

WFormBorderRegistry bordersOf(Object controller) =>
    _registries[controller] ??= WFormBorderRegistry();
