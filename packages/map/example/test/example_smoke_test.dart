import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_map/w_tools_map.dart';
import 'package:w_tools_map_example/main.dart';

void main() {
  testWidgets('地图与门店选择器渲染', (tester) async {
    await tester.pumpWidget(const MapExampleApp());
    await tester.pump();

    expect(find.byType(WMap<Shop>), findsOneWidget);
    expect(find.text('门店地图'), findsOneWidget);
    expect(find.text('外滩店'), findsOneWidget);
  });

  testWidgets('筛选门店会更新 WMapZone', (tester) async {
    await tester.pumpWidget(const MapExampleApp());
    await tester.pump();

    await tester.tap(find.byTooltip('只看静安店'));
    await tester.pump();

    expect(find.text('静安寺店'), findsOneWidget);
    expect(find.text('外滩店'), findsNothing);
  });

  testWidgets('从列表选中门店后显示卡片', (tester) async {
    await tester.pumpWidget(const MapExampleApp());
    await tester.pump();

    await tester.tap(find.text('外滩店'));
    await tester.pump();

    expect(find.text('31.24, 121.49'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
  });
}
