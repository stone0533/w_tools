import 'package:get/get.dart';

/// 在 `WAppPlugin.onInit` 里注册 app 生命周期的 GetX 服务。
///
/// 直接用 `Get.putAsync` 时，下面这种箭头写法会把实例注册到 `void` 下：
///
/// ```dart
/// Future<void> onInit() => Get.putAsync(() => PbeService().init());
/// ```
///
/// `Get.putAsync<S>` 的返回类型是 `Future<S>`，在 `Future<void>` 的期望类型下
/// `S` 被推断成 `void`：服务照常在跑，但 `Get.isRegistered<PbeService>()` 是
/// `false`、`Get.isRegistered<void>()` 是 `true`，`Get.find<PbeService>()` 抛
/// 「not found」——analyzer 和普通单测都不报，只有真机走到那条路径才炸。
///
/// 本函数返回 `Future<void>` 而不是 `Future<T>`：`onInit` 的返回类型不再参与
/// `T` 的推断，`T` 只由 factory 推断，所以**箭头写法也是对的**：
///
/// ```dart
/// class PbePlugin extends WAppPlugin {
///   @override
///   String get name => 'pbe';
///
///   @override
///   Future<void> onInit() => registerService(() => PbeService().init());
/// }
/// ```
///
/// 拿到实例用 `Get.find<T>()`；注册完成后它已经可用。
///
/// 修复的关键是**返回 `Future<void>`**：`onInit` 的 `Future<void>` 不再参与 `T`
/// 的推断，`T` 只由 factory 得到。`T extends GetxService` 只表达「这个 helper
/// 注册的是 GetX 服务」，不是修复手段。
/// [tag] / [permanent] 原样透传给 `Get.putAsync`，默认值与 GetX 一致。
Future<void> registerService<T extends GetxService>(
  Future<T> Function() factory, {
  String? tag,
  bool permanent = false,
}) => Get.putAsync<T>(factory, tag: tag, permanent: permanent);
