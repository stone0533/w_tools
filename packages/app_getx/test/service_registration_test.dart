import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

class CounterService extends GetxService {
  Future<CounterService> init() async => this;
}

class TaggedService extends GetxService {
  Future<TaggedService> init() async => this;
}

/// 复刻消费方插件里的写法：`onInit` 用箭头直接返回注册结果。
///
/// 直接用 `Get.putAsync` 时这里会把实例注册到 `void`（issue #53）；
/// 走 `registerService` 后 `T` 由 factory 推断，注册在 `CounterService` 下。
Future<void> arrowStyleOnInit() => registerService(() => CounterService().init());

void main() {
  tearDown(Get.reset);

  test('箭头写法（无显式泛型）注册到 T 下，而不是 void', () async {
    await arrowStyleOnInit();

    expect(Get.isRegistered<CounterService>(), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
    expect(Get.find<CounterService>(), isA<CounterService>());
  });

  test('显式泛型 + 块体写法同样注册到 T 下', () async {
    await registerService<TaggedService>(() => TaggedService().init());

    expect(Get.isRegistered<TaggedService>(), isTrue);
    expect(Get.isRegistered<void>(), isFalse);
    expect(Get.find<TaggedService>(), isA<TaggedService>());
  });

  test('tag 区分同一类型的多个实例', () async {
    await registerService<CounterService>(() => CounterService().init(), tag: 'a');
    await registerService<CounterService>(() => CounterService().init(), tag: 'b');

    final a = Get.find<CounterService>(tag: 'a');
    final b = Get.find<CounterService>(tag: 'b');
    expect(a, isA<CounterService>());
    expect(b, isA<CounterService>());
    expect(a, isNot(same(b)));
  });
}
