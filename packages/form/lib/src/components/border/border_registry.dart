import 'package:flutter/foundation.dart' show ValueNotifier, internal;

/// 表单字段的边框登记（包内实现，不导出）。
///
/// 维护两件事：
/// - 字段名 → owner：同名字段在 debug 直接报可读错误（不再依赖 GlobalKey 冲突）；
/// - 字段名 → 错误通道：`WFormBorder` 订阅自己的通道渲染错误，不需要 GlobalKey 反查。
///
/// 业务侧不要直接用本类：读写错误走 `WFormController.setError` / `clearError`。
@internal
class WFormBorderRegistry {
  /// 边框 owner 登记（仅用于检测同名字段，不保存任何 widget 状态）
  final Map<String, Object> _owners = {};

  /// 每个字段的错误通道（字段名 → 当前错误列表）
  final Map<String, ValueNotifier<List<String>?>> _channels = {};

  /// 取（或创建）指定字段的错误通道
  ValueNotifier<List<String>?> channelOf(String name) =>
      _channels.putIfAbsent(name, () => ValueNotifier<List<String>?>(null));

  /// 注销并释放指定字段的错误通道
  void removeChannel(String name) {
    _channels.remove(name)?.dispose();
  }

  /// 清空指定字段的错误（不创建新通道）
  void clearChannel(String name) {
    _channels[name]?.value = null;
  }

  /// 注册字段边框（同名字段在 debug 直接报出来）
  void register(String name, {required Object owner}) {
    final existing = _owners[name];
    assert(
      existing == null || identical(existing, owner),
      '字段 name 重复：$name。同一 WForm 内 name 必须唯一'
      '（检查是否同时挂载了两个 name 相同的字段，或边框用了子字段的名字）。',
    );
    _owners[name] = owner;
    channelOf(name);
  }

  /// 注销字段边框（只清自己的登记）
  void unregister(String name, {required Object owner}) {
    if (!identical(_owners[name], owner)) return;
    _owners.remove(name);
    removeChannel(name);
  }

  /// 该字段是否已注册边框（`bordered: false` 的字段没有）
  bool has(String name) => _channels.containsKey(name);
}
