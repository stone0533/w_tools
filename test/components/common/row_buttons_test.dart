import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/components/common/row_buttons.dart';

void main() {
  group('WRowButtonsController - initialIndex 可空测试', () {
    const length = 5;

    test('不传入 initialIndex 时，index 应为 null（无预选）', () {
      final controller = WRowButtonsController(length: length);
      expect(controller.index, isNull);
      controller.dispose();
    });

    test('传入 initialIndex 为 null 时，index 应为 null', () {
      final controller = WRowButtonsController(length: length, initialIndex: null);
      expect(controller.index, isNull);
      controller.dispose();
    });

    test('传入合法 initialIndex 时，index 应等于该值', () {
      final controller = WRowButtonsController(length: length, initialIndex: 2);
      expect(controller.index, equals(2));
      controller.dispose();
    });

    test('initialIndex 超出范围（>= length）应抛 ArgumentError', () {
      expect(
        () => WRowButtonsController(length: length, initialIndex: length),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('initialIndex 超出范围（负数）应抛 ArgumentError', () {
      expect(
        () => WRowButtonsController(length: length, initialIndex: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('length 为 0 时应抛 ArgumentError', () {
      expect(
        () => WRowButtonsController(length: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('animateTo 后 index 更新为新值', () {
      final controller = WRowButtonsController(length: length, initialIndex: null);
      expect(controller.index, isNull);
      controller.animateTo(3);
      expect(controller.index, equals(3));
      controller.dispose();
    });

    test('jumpTo 后 index 更新为新值', () {
      final controller = WRowButtonsController(length: length);
      expect(controller.index, isNull);
      controller.jumpTo(1);
      expect(controller.index, equals(1));
      controller.dispose();
    });

    test('监听 index 变化应正常触发', () {
      final controller = WRowButtonsController(length: length);
      int? lastValue;
      controller.addListener(() {
        lastValue = controller.index;
      });
      controller.jumpTo(2);
      expect(lastValue, equals(2));
      controller.dispose();
    });

    test('selectedIndexNotifier 类型应为 ValueNotifier<int?>', () {
      final controller = WRowButtonsController(length: length);
      // 验证 ValueNotifier 的 value 可以是 null
      expect(controller.selectedIndexNotifier.value, isNull);
      controller.jumpTo(1);
      expect(controller.selectedIndexNotifier.value, equals(1));
      controller.dispose();
    });

    test('deselect 后 index 回到 null', () {
      final controller = WRowButtonsController(length: length, initialIndex: 2);
      expect(controller.index, equals(2));
      controller.deselect();
      expect(controller.index, isNull);
      controller.dispose();
    });

    test('deselect 后监听器触发且拿到 null', () {
      final controller = WRowButtonsController(length: length);
      int? lastValue = -1;
      controller.addListener(() {
        lastValue = controller.index;
      });
      controller.jumpTo(2);
      expect(lastValue, equals(2));
      controller.deselect();
      expect(lastValue, isNull);
      controller.dispose();
    });

    test('deselect 后可以重新选中', () {
      final controller = WRowButtonsController(length: length, initialIndex: 1);
      controller.deselect();
      expect(controller.index, isNull);
      controller.jumpTo(3);
      expect(controller.index, equals(3));
      controller.dispose();
    });
  });

  group('WRowButtons - Widget Test', () {
    const length = 5;

    testWidgets('initialIndex 为 null 时，所有按钮都不被选中', (tester) async {
      final controller = WRowButtonsController(length: length);
      final selectedStates = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WRowButtons(
              controller: controller,
              builder: (context, index, isSelected) {
                selectedStates.add(isSelected);
                return Text('btn$index-$isSelected');
              },
            ),
          ),
        ),
      );

      // 初始状态全部不选中
      expect(controller.index, isNull);
      expect(selectedStates.length, equals(length));
      expect(selectedStates.every((s) => s == false), isTrue);
    });

    testWidgets('initialIndex 为 2 时，只有第 3 个按钮被选中', (tester) async {
      final controller = WRowButtonsController(length: length, initialIndex: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WRowButtons(
              controller: controller,
              builder: (context, index, isSelected) {
                return Text(isSelected ? 'SELECTED-$index' : 'btn$index');
              },
            ),
          ),
        ),
      );

      expect(controller.index, equals(2));
      expect(find.text('SELECTED-2'), findsOneWidget);
      expect(find.textContaining('SELECTED'), findsOneWidget);
    });

    testWidgets('点击按钮后，index 更新且选中状态切换', (tester) async {
      final controller = WRowButtonsController(length: length);
      final tappedIndices = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WRowButtons(
              controller: controller,
              onTap: tappedIndices.add,
              builder: (context, index, isSelected) {
                return Text(isSelected ? 'SEL-$index' : 'btn$index');
              },
            ),
          ),
        ),
      );

      // 点击第 4 个按钮
      await tester.tap(find.text('btn3'));
      await tester.pumpAndSettle();

      expect(tappedIndices, equals([3]));
      expect(controller.index, equals(3));
      expect(find.text('SEL-3'), findsOneWidget);
    });

    testWidgets('deselect 后所有按钮恢复为未选中状态', (tester) async {
      final controller = WRowButtonsController(length: length, initialIndex: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WRowButtons(
              controller: controller,
              builder: (context, index, isSelected) {
                return Text(isSelected ? 'SEL-$index' : 'btn$index');
              },
            ),
          ),
        ),
      );

      // 初始：选中第 3 个
      expect(find.text('SEL-2'), findsOneWidget);

      // deselect
      controller.deselect();
      await tester.pump();

      expect(controller.index, isNull);
      expect(find.textContaining('SEL-'), findsNothing);
      expect(find.text('btn2'), findsOneWidget);
    });
  });
}
