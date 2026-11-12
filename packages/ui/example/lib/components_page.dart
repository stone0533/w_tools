// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'components_overview_sections.dart';
import 'components_state_sections.dart';
import 'components_page_sections.dart';

/// 覆盖非 WImage 的核心组件：文字、徽标、裁剪、进度、步骤、
/// 列表、横向按钮、Tab、底部导航、通知与保活。
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> with TickerProviderStateMixin {
  late final WNavController _navController;
  int _selectedTag = 0;
  late final WImageController _imageController;
  double? _scrollPercent;
  double _actionOffset = 0;

  @override
  void initState() {
    super.initState();
    _navController = WNavController(length: 3, vsync: this);
    _imageController = WImageController();
  }

  @override
  void dispose() {
    _navController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...buildComponentsOverviewSections(context),
        ...buildComponentsStateSections(
          context: context,
          selectedTag: _selectedTag,
          onSelectedTag: (index) => setState(() => _selectedTag = index),
          actionOffset: _actionOffset,
          onActionOffset: (offset) => setState(() => _actionOffset = offset),
          navController: _navController,
          scrollPercent: _scrollPercent,
          onScrollPercent: (value) => setState(() => _scrollPercent = value),
        ),
        ...buildComponentsImageSections(imageController: _imageController),
        const SizedBox(height: 24),
      ],
    );
  }
}
