import 'package:flutter/material.dart';

import 'pages/advanced_fields_page.dart';
import 'pages/border_page.dart';
import 'pages/login_page.dart';
import 'pages/popup_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const FormExampleApp());
}

class FormExampleApp extends StatelessWidget {
  const FormExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_form 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF10B981),
        useMaterial3: true,
      ),
      home: const _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          LoginExamplePage(),
          ProfileExamplePage(),
          PopupExamplePage(),
          AdvancedFieldsPage(),
          BorderExamplePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.login_rounded),
            label: '登录',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: '会员资料',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_drop_down_circle_outlined),
            label: '弹层',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: '高级',
          ),
          NavigationDestination(
            icon: Icon(Icons.border_style_outlined),
            label: '边框',
          ),
        ],
      ),
    );
  }
}
