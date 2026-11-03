# App 根装配：主题 + 排版 + 全局提示

```dart
void main() {
  runApp(
    // 普通 + sliver 的全局默认视图（在 MaterialApp 外也可以）
    WAsyncTheme(
      sliverLoadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      sliverEmptyBuilder: (_) => const Center(child: Text('暂无数据')),
      child: WToastTheme(
        style: WToastStyle.defaults,
        child: MaterialApp(
          title: 'Demo',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF3949AB),
          ).withWTextStyles(WTextStyles.fromTextTheme(ThemeData().textTheme)),
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: const HomePage(),
        ),
      ),
    ),
  );
}
```

要点：

- `WAsyncTheme` / `WToastTheme` 是 `InheritedWidget`，放在 `MaterialApp` 外也能被子树读到；
- `WTextStyles.fromTextTheme` 的入参决定未覆盖槽位的基线；应用里通常传设计给的 `TextTheme`；
- 不要在 `main()` 顶层 / `static final` 里计算 `.sp`（ScreenUtil 尚未 configure）；
- 页面里：`WToast.showSuccess('ok', context: context)` 会自动读 `WToastTheme`；`WAsyncView` 自动读 `WAsyncTheme`。
