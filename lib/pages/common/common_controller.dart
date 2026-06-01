import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

enum NavRefreshTransitionStage { idle, exit, enter }

class NavRefreshTransitionState {
  const NavRefreshTransitionState({
    required this.tick,
    required this.stage,
  });

  const NavRefreshTransitionState.idle()
    : tick = 0,
      stage = NavRefreshTransitionStage.idle;

  final int tick;
  final NavRefreshTransitionStage stage;
}

mixin ScrollOrRefreshMixin {
  static const navRefreshExitDuration = Duration(milliseconds: 220);
  static const navRefreshEnterDuration = Duration(milliseconds: 320);

  ScrollController get scrollController;
  final Rx<NavRefreshTransitionState> navRefreshTransition =
      const NavRefreshTransitionState.idle().obs;
  bool _isNavRefreshAnimating = false;

  void animateToTop() => scrollController.animToTop();

  void jumpToTop() => scrollController.jumpToTop();

  Future<void> onRefresh();

  Future<void> triggerNavRefresh() async {
    if (_isNavRefreshAnimating) return;
    _isNavRefreshAnimating = true;

    final tick = navRefreshTransition.value.tick + 1;
    navRefreshTransition.value = NavRefreshTransitionState(
      tick: tick,
      stage: NavRefreshTransitionStage.exit,
    );

    await Future<void>.delayed(navRefreshExitDuration);
    jumpToTop();
    navRefreshTransition.value = NavRefreshTransitionState(
      tick: tick,
      stage: NavRefreshTransitionStage.enter,
    );
    unawaited(_settleNavRefreshTransition(tick));

    try {
      await onRefresh();
    } finally {
      _isNavRefreshAnimating = false;
    }
  }

  Future<void> _settleNavRefreshTransition(int tick) async {
    await Future<void>.delayed(navRefreshEnterDuration);
    final value = navRefreshTransition.value;
    if (value.tick == tick && value.stage == NavRefreshTransitionStage.enter) {
      navRefreshTransition.value = NavRefreshTransitionState(
        tick: tick,
        stage: NavRefreshTransitionStage.idle,
      );
    }
  }

  void toTopOrRefresh() {
    if (scrollController.hasClients) {
      if (scrollController.position.pixels == 0) {
        EasyThrottle.throttle(
          'topOrRefresh',
          const Duration(milliseconds: 500),
          onRefresh,
        );
      } else {
        animateToTop();
      }
    }
  }
}

abstract class CommonController<R, T> extends GetxController
    with ScrollOrRefreshMixin {
  @override
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  Rx<LoadingState> get loadingState;

  Future<LoadingState<R>> customGetData();

  Future<void> queryData([bool isRefresh = true]);

  bool customHandleResponse(bool isRefresh, Success<R> response) {
    return false;
  }

  bool handleError(String? errMsg) {
    return false;
  }

  @override
  Future<void> onRefresh() {
    return queryData();
  }

  Future<void> onLoadMore() {
    return queryData(false);
  }

  Future<void> onReload() {
    return onRefresh();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
