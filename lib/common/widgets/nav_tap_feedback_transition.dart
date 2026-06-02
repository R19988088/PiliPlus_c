import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:flutter/material.dart';

class NavTapFeedbackTransition extends StatefulWidget {
  const NavTapFeedbackTransition({
    super.key,
    required this.tick,
    required this.child,
    this.enabled = true,
  });

  final int tick;
  final Widget child;
  final bool enabled;

  @override
  State<NavTapFeedbackTransition> createState() =>
      _NavTapFeedbackTransitionState();
}

class _NavTapFeedbackTransitionState extends State<NavTapFeedbackTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ScrollOrRefreshMixin.navTapFeedbackDuration,
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 50,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 50,
          end: 0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 58,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant NavTapFeedbackTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.tick != oldWidget.tick) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        );
      },
    );
  }
}
