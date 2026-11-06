// 组件
export 'src/components/components.dart';

// 扩展
export 'src/extensions/box_decoration.dart';
export 'src/extensions/color.dart';
export 'src/extensions/global_key.dart';
export 'src/extensions/num.dart';
export 'src/extensions/string.dart';
export 'src/extensions/text_style.dart';
export 'src/extensions/widget.dart';

// 公开 API 里出现的第三方类型：由本包 barrel 统一转出，
// 消费方只依赖 w_tools_ui 就能构造 WBadgeConfig。
export 'package:badges/badges.dart' show BadgePosition, BadgeStyle;

// 工具
export 'src/styles/gradients.dart';
export 'src/styles/shadows.dart';

export 'src/utils/assets.dart';
export 'src/utils/screen.dart';
