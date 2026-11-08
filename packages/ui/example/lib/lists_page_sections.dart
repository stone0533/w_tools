import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 列表演示的通知 / 保活 sections。
List<Widget> buildListsNotificationSections({
  required BuildContext context,
  required ValueNotifier<int> notifications,
  required ValueNotifier<int> bubbled,
  required ValueNotifier<double?> percent,
  required bool prevent,
  required ValueChanged<bool> onPreventChanged,
  required bool keepAlive,
}) {
  return [
    DemoSection(
      title: 'WNotificationListener',
      subtitle: '百分比只处理 depth 0 的 ScrollUpdateNotification',
      child: Builder(
        builder: (context) {
          final probe = WNotificationListener<ScrollNotification>(
            onNotificationPercentage: (value) => percent.value = value,
            preventNotificationPropagation: prevent,
            onNotification: prevent
                ? null
                : (_) {
                    notifications.value++;
                    return false;
                  },
            child: ListView.builder(
              itemCount: 30,
              itemBuilder: (context, index) => SizedBox(
                height: 36,
                child: Center(
                  child: WText(
                    text: 'scroll $index',
                    variant: WTextVariant.caption,
                  ),
                ),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DemoBox(
                height: 160,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    bubbled.value++;
                    return false;
                  },
                  child: probe,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const WText(
                    text: 'preventNotificationPropagation',
                    variant: WTextVariant.caption,
                  ),
                  Switch(
                    value: prevent,
                    onChanged: onPreventChanged,
                  ),
                ],
              ),
              ValueListenableBuilder<int>(
                valueListenable: notifications,
                builder: (context, value, _) =>
                    DemoKeyValue(label: 'onNotification', value: '$value'),
              ),
              ValueListenableBuilder<double?>(
                valueListenable: percent,
                builder: (context, value, _) => DemoKeyValue(
                  label: 'percentage',
                  value: value?.toStringAsFixed(2) ?? '-',
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: bubbled,
                builder: (context, value, _) => DemoKeyValue(label: 'bubbled 到外层', value: '$value'),
              ),
            ],
          );
        },
      ),
    ),
    DemoSection(
      title: 'WKeepAliveWrapper',
      subtitle: '与 WListView 的 keepAlive 互为补充；页面级保活用它',
      child: DemoBox(
        height: 160,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => WKeepAliveWrapper(
            keepAlive: keepAlive,
            child: SizedBox(
              height: 48,
              child: Center(
                child: WText(
                  text: 'keepAlive=$keepAlive · item $index',
                  variant: WTextVariant.body,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ];
}
