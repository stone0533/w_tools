import 'package:flutter/material.dart';

import 'border/border.dart';
import 'form_icons.dart';
import 'border/read_only_scope.dart';
import 'form_scope.dart';
import 'form_field_style.dart';
import 'form_theme.dart';
import 'form_settings.dart';
import 'validation/validator.dart';
import 'form_controller.dart';

final Expando<Object> _controllerHosts = Expando<Object>();

bool _claimController(WFormController controller, Object host) {
  final current = _controllerHosts[controller];
  if (current == null || identical(current, host)) {
    _controllerHosts[controller] = host;
    return true;
  }
  return false;
}

void _releaseController(WFormController controller, Object host) {
  if (identical(_controllerHosts[controller], host)) _controllerHosts[controller] = null;
}

/// 表单页面容器。
///
/// 一次性组合 [WFormTheme]、[WFormScope] 与 [WFormReadOnlyScope]，
/// 业务页面不再需要重复写三层嵌套。
///
/// ```dart
/// WForm(
///   controller: form,
///   borderStyle: WFormBorderStyle.standard(),
///   child: ListView(...),
/// )
/// ```
///
/// 图标：显式 [icons] 优先；未传时继承祖先 [WFormTheme]，最后回退
/// [WFormIcons.defaults]。
///
/// 校验设置：显式传 [validatorSettings] 时完全以它为准；未传时注入
/// `const WFormValidatorSettings(showBorderError: true)`，保证 `validate()` 失败时
/// 至少有边框错误可看。没有边框样式（例如显式 `const WFormBorderStyle()`）时
/// 不会渲染文案，效果等同“没有错误展示”。
class WForm extends StatefulWidget {
  const WForm({
    super.key,
    required this.controller,
    required this.child,
    this.borderStyle,
    this.fieldStyle,
    this.validatorSettings,
    this.readOnly = false,
    this.autovalidateMode,
    this.onChanged,
    this.icons,
  });

  final WFormController controller;
  final Widget child;
  final WFormBorderStyle? borderStyle;
  final WFormFieldStyle? fieldStyle;
  final WFormValidatorSettings? validatorSettings;
  final bool readOnly;
  final AutovalidateMode? autovalidateMode;

  /// 任一字段值变化后回调，参数为当前整表值。
  final ValueChanged<Map<String, dynamic>>? onChanged;

  /// 图标集合；未传时继承外层 [WFormTheme]，最后回退 [WFormIcons.defaults]
  final WFormIcons? icons;

  @override
  State<WForm> createState() => _WFormState();
}

class _WFormState extends State<WForm> {
  /// 实际生效的校验设置：显式传入优先；未传时默认显示边框错误。
  WFormValidatorSettings? _settings;

  /// 当前 state 是否持有 controller 的挂载登记
  bool _ownsController = false;

  /// 是否为「等待 owner 释放」排过一次 post-frame 重试
  bool _recoveryScheduled = false;

  /// 主题派生的默认边框配置（按 ThemeData 实例缓存，避免每帧重建）
  WFormBorderStyle? _defaultBorderConfig;
  ThemeData? _defaultBorderTheme;

  @override
  void initState() {
    super.initState();
    _ownsController = _claimController(widget.controller, this);
    if (_ownsController) _syncSettings();
  }

  @override
  void activate() {
    super.activate();
    _ownsController = _claimController(widget.controller, this);
    if (_ownsController) _syncSettings();
  }

  @override
  void deactivate() {
    _releaseController(widget.controller, this);
    _ownsController = false;
    super.deactivate();
  }

  void _syncSettings() {
    // 现在默认边框一定存在（显式 / 祖先主题 / fromTheme），
    // 未显式配置校验设置时默认把错误显示在边框上。
    _settings = widget.validatorSettings ?? const WFormValidatorSettings(showBorderError: true);
    setFormValidatorSettings(widget.controller, _settings);
  }

  /// 边框配置解析：显式参数 > 祖先 [WFormThemeData] > 主题派生默认值。
  WFormBorderStyle? _resolveBorderStyle(BuildContext context) {
    final explicit = widget.borderStyle;
    if (explicit != null) return explicit;

    final inherited = WFormThemeData.of(context)?.borderStyle;
    if (inherited != null) return inherited;

    final theme = Theme.of(context);
    if (!identical(_defaultBorderTheme, theme) || _defaultBorderConfig == null) {
      _defaultBorderTheme = theme;
      _defaultBorderConfig = WFormBorderStyle.fromTheme(theme);
    }
    return _defaultBorderConfig;
  }

  @override
  void didUpdateWidget(covariant WForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (formValidatorSettingsOf(oldWidget.controller) == _settings) {
        setFormValidatorSettings(oldWidget.controller, null);
      }
      _releaseController(oldWidget.controller, this);
      _ownsController = _claimController(widget.controller, this);
    }
    if (_ownsController &&
        (oldWidget.controller != widget.controller ||
            oldWidget.validatorSettings != widget.validatorSettings)) {
      // 只跟随 controller / validatorSettings：边框样式与校验设置无关，
      // 换 borderStyle 不能把用户手动注入的 controller.validatorSettings 覆盖掉。
      _syncSettings();
    }
  }

  /// owner 卸载发生在本帧更晚的时候，post-frame 再试一次并触发重建。
  void _scheduleRecovery() {
    if (_recoveryScheduled) return;
    _recoveryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoveryScheduled = false;
      if (!mounted || _ownsController) return;
      if (_claimController(widget.controller, this)) {
        _syncSettings();
        setState(() => _ownsController = true);
      }
    });
  }

  @override
  void dispose() {
    _releaseController(widget.controller, this);
    if (formValidatorSettingsOf(widget.controller) == _settings) {
      setFormValidatorSettings(widget.controller, null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ownsController) {
      // owner 卸载后允许自动恢复；claim 是幂等的，不会抢走别人的登记。
      if (_claimController(widget.controller, this)) {
        _ownsController = true;
        // 恢复挂载时也必须重新注入默认校验设置：前一个 WForm 的 dispose 会把它清空。
        _syncSettings();
      } else {
        _scheduleRecovery();
      }
    }
    if (!_ownsController) {
      // 不抛异常：抛在 build 里会连带 ErrorWidget 撑破布局，这里直接给出可读提示。
      return const _WFormDuplicateControllerNotice();
    }

    // 未显式传的图标继承外层 WFormTheme，实现「App 统一图标」。
    final inheritedTheme = WFormThemeData.of(context);
    return WFormTheme(
      icons: widget.icons ?? inheritedTheme?.icons,
      borderStyle: _resolveBorderStyle(context),
      child: WFormFieldStyleScope(
        style: widget.fieldStyle,
        child: WFormScope(
          formData: widget.controller,
          autovalidateMode: widget.autovalidateMode,
          onChanged: widget.onChanged,
          child: WFormReadOnlyScope(
            readOnly: widget.readOnly,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 同一个 controller 被多个 WForm 同时挂载时的可读提示。
class _WFormDuplicateControllerNotice extends StatelessWidget {
  const _WFormDuplicateControllerNotice();

  /// 稳定 key：测试按 key 断言，改文案不会让用例变红
  static const ValueKey<String> widgetKey = ValueKey<String>('w-form-duplicate-controller');

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: widgetKey,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'WFormController 重复挂载：同一个 WFormController 不能同时被两个 WForm 使用。'
          '请各自持有 controller，或在页面间传递值。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
