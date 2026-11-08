import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'app_buttons.dart';
import 'demo_widgets.dart';

/// 按钮页的交互 / 动效 sections。
List<Widget> buildButtonsInteractionSections({
  required BuildContext context,
  required int taps,
  required int longPresses,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
}) {
  return [
    DemoSection(
      title: '14. 长按 / loadingBuilder',
      subtitle: 'loadingBuilder 自定义加载中占位；长按走 onLongPress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WButton(
                style: AppButtons.secondary(context),
                label: '长按我',
                onTap: () => onTap(),
                onLongPress: () => onLongPress(),
              ),
              WButton(
                style: AppButtons.primary(context),
                label: '提交中',
                loading: true,
                loadingBuilder: (context) => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'onLongPress 触发 $longPresses 次',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    DemoSection(
      title: '15. WButtonMotion：opacity / scale / none',
      subtitle: '通过 WButton.motion 局部覆盖',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          WButton(
            style: AppButtons.primary(context),
            motion: const WButtonMotion(
              effect: WPressEffect.scale,
              pressedScale: 0.96,
            ),
            label: 'scale 按压',
            onTap: () {},
          ),
          WButton(
            style: AppButtons.secondary(context),
            motion: const WButtonMotion(
              effect: WPressEffect.opacity,
              pressedOpacity: 0.6,
            ),
            label: 'opacity 按压',
            onTap: () {},
          ),
          WButton(
            style: AppButtons.text(context),
            motion: const WButtonMotion(effect: WPressEffect.none),
            label: '无按压效果',
            onTap: () {},
          ),
        ],
      ),
    ),
    DemoSection(
      title: '16. WPressable：enabled / onLongPress / pressedOpacity',
      subtitle: '无 button 语义；需要键盘/最小点击区域时换 WButton',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WPressable(
            enabled: false,
            onTap: () => onTap(),
            child: const Card(
              child: ListTile(
                leading: Icon(Icons.block),
                title: Text('enabled: false（点击无效）'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          WPressable(
            pressedOpacity: 0.6,
            onLongPress: () => onLongPress(),
            onTap: () => onTap(),
            child: const Card(
              child: ListTile(
                leading: Icon(Icons.touch_app_outlined),
                title: Text('onTap + onLongPress + pressedOpacity'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'taps=$taps · longPress=$longPresses',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  ];
}
