import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:flutter/material.dart';

String navRefreshTransitionKeyForState(NavRefreshTransitionState state) {
  return switch (state.stage) {
    NavRefreshTransitionStage.exit => 'exit-${state.tick}',
    NavRefreshTransitionStage.enter ||
    NavRefreshTransitionStage.idle => 'content-${state.tick}',
  };
}

class NavRefreshTransition extends StatelessWidget {
  const NavRefreshTransition({
    super.key,
    required this.state,
    required this.child,
  });

  final NavRefreshTransitionState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(navRefreshTransitionKeyForState(state));
    return ClipRect(
      child: AnimatedSwitcher(
        duration: state.stage == NavRefreshTransitionStage.exit
            ? ScrollOrRefreshMixin.navRefreshExitDuration
            : ScrollOrRefreshMixin.navRefreshEnterDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (widget, animation) {
          final isCurrent = widget.key == key;
          final offsetTween = Tween<Offset>(
            begin: _beginOffset(state.stage, isCurrent),
            end: Offset.zero,
          );
          final fadeTween = Tween<double>(
            begin: state.stage == NavRefreshTransitionStage.enter && isCurrent
                ? 0.98
                : 1,
            end: 1,
          );
          return SlideTransition(
            position: animation.drive(offsetTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: widget,
            ),
          );
        },
        child: KeyedSubtree(
          key: key,
          child: child,
        ),
      ),
    );
  }

  Offset _beginOffset(NavRefreshTransitionStage stage, bool isCurrent) {
    return switch (stage) {
      NavRefreshTransitionStage.exit when isCurrent => const Offset(0, -0.18),
      NavRefreshTransitionStage.exit => const Offset(0, 0.18),
      NavRefreshTransitionStage.enter when isCurrent => const Offset(0, -0.16),
      NavRefreshTransitionStage.enter => const Offset(0, 0.08),
      NavRefreshTransitionStage.idle => Offset.zero,
    };
  }
}
