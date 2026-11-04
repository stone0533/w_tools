library w_tools_toast;

// 底层封装
export 'src/toast.dart';

// 样式与调用入口
export 'src/toast_style.dart';
export 'src/toast_theme.dart';

// 公开 API 里出现的第三方类型（初始化、导航观察者、CancelFunc）由本包统一转出。
export 'package:bot_toast/bot_toast.dart' show BotToastInit, BotToastNavigatorObserver, CancelFunc;
