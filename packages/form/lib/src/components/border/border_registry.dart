import 'package:flutter/widgets.dart';

import 'border.dart';

/// 边框 key 注册表（包内实现，不对外导出）。
///
/// 以 `WFormController` 实例作为 [Expando] 键，避免把内部管道暴露在 controller
/// 的公开成员上。`controller` 用 `Object` 接收，避免与 `form_controller.dart`
/// 形成 import 环。
final Expando<Map<String, GlobalKey<WFormBorderState>>> _keys = Expando();
final Expando<Map<String, Object>> _owners = Expando();

Map<String, GlobalKey<WFormBorderState>> _keysOf(Object controller) =>
    _keys[controller] ??= <String, GlobalKey<WFormBorderState>>{};

Map<String, Object> _ownersOf(Object controller) => _owners[controller] ??= <String, Object>{};

bool hasBorder(Object controller, String name) => _keysOf(controller).containsKey(name);

GlobalKey<WFormBorderState>? borderKeyOf(Object controller, String name) =>
    _keysOf(controller)[name];

GlobalKey<WFormBorderState> ensureBorderKey(Object controller, String name, {Object? owner}) {
  final keys = _keysOf(controller);
  if (owner != null) {
    final owners = _ownersOf(controller);
    final existing = owners[name];
    assert(
      existing == null || identical(existing, owner),
      '字段 name 重复：$name。同一 WForm 内 name 必须唯一'
      '（检查是否同时挂载了两个 name 相同的字段，或边框用了子字段的名字）。',
    );
    owners[name] = owner;
  }
  return keys.putIfAbsent(name, () => GlobalKey<WFormBorderState>());
}

void removeBorderKey(Object controller, String name, {Object? owner}) {
  if (owner != null && !identical(_ownersOf(controller)[name], owner)) return;
  _ownersOf(controller).remove(name);
  _keysOf(controller).remove(name);
}
