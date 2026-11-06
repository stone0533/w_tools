import 'package:flutter/material.dart';

/// WActionRow / WSelectableRow 共用的横向滚动容器。
///
/// 只有传入 [onScroll] 且没有外部 [controller] 时才自建 controller；
/// 外部 controller 的生命周期由调用方负责。
class WActionRowScrollView extends StatefulWidget {
  const WActionRowScrollView({
    super.key,
    required this.children,
    this.padding,
    this.spacing = 8,
    this.physics,
    this.controller,
    this.onScroll,
    this.scrollViewKey,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final ValueChanged<double>? onScroll;
  final Key? scrollViewKey;

  @override
  State<WActionRowScrollView> createState() => _WActionRowScrollViewState();
}

class _WActionRowScrollViewState extends State<WActionRowScrollView> {
  ScrollController? _internalController;
  ScrollController? _listenedController;

  ScrollController? get _effectiveController {
    if (widget.controller != null) return widget.controller;
    if (widget.onScroll == null) return null;
    return _internalController ??= ScrollController();
  }

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  @override
  void didUpdateWidget(WActionRowScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onScroll != widget.onScroll || oldWidget.controller != widget.controller) {
      _detachListener();
      _attachListener();
    }
  }

  void _attachListener() {
    final onScroll = widget.onScroll;
    final controller = _effectiveController;
    if (onScroll == null || controller == null) return;
    _listenedController = controller;
    controller.addListener(_notify);
  }

  void _detachListener() {
    _listenedController?.removeListener(_notify);
    _listenedController = null;
  }

  void _notify() {
    final controller = _listenedController;
    final onScroll = widget.onScroll;
    if (controller != null && onScroll != null) onScroll(controller.offset);
  }

  @override
  void dispose() {
    _detachListener();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: widget.scrollViewKey,
      scrollDirection: Axis.horizontal,
      controller: _effectiveController,
      physics: widget.physics,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: Wrap(spacing: widget.spacing, children: widget.children),
      ),
    );
  }
}
