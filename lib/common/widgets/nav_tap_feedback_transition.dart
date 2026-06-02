import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:flutter/material.dart';

class NavTapFeedbackTransition extends StatefulWidget {
  const NavTapFeedbackTransition({
    super.key,
    required this.progress,
    required this.child,
    this.enabled = true,
  });

  final double progress;
  final Widget child;
  final bool enabled;

  @override
  State<NavTapFeedbackTransition> createState() =>
      _NavTapFeedbackTransitionState();
}

class _NavTapFeedbackTransitionState extends State<NavTapFeedbackTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _offset;
  double _offsetValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ScrollOrRefreshMixin.navTapFeedbackDuration,
    );
    _offset = Tween<double>(
      begin: 0,
      end: 0,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller);
    _offsetValue = _progressOffset;
  }

  double get _progressOffset =>
      widget.enabled
          ? widget.progress.clamp(0.0, 1.0) *
                ScrollOrRefreshMixin.navTapFeedbackMaxOffset
          : 0.0;

  @override
  void didUpdateWidget(covariant NavTapFeedbackTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _animateBack();
      return;
    }

    final offset = _progressOffset;
    if (offset > 0) {
      _offset.removeListener(_syncOffset);
      _controller.stop();
      setState(() => _offsetValue = offset);
    } else if (_offsetValue > 0) {
      _animateBack();
    }
  }

  void _animateBack() {
    if (_offsetValue <= 0) return;
    _offset.removeListener(_syncOffset);
    _offset = Tween<double>(
      begin: _offsetValue,
      end: 0,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller)
      ..addListener(_syncOffset);
    _controller.forward(from: 0);
  }

  void _syncOffset() {
    setState(() => _offsetValue = _offset.value);
  }

  @override
  void dispose() {
    _offset.removeListener(_syncOffset);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _offsetValue),
      child: widget.child,
    );
  }
}
