- **Toasts** (`WToast` + `WToastStyle` / `WToastTheme`): install `BotToastInit` +
  `BotToastNavigatorObserver` once at the root, otherwise every toast fails silently; use
  `WToast.showModal` for barrier hints, not `showCustomDialog`. Details: `explain WToast`.
