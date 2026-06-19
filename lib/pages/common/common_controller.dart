import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/widgets.dart' show Curves, ScrollController, VoidCallback;
import 'package:get/get.dart';

enum NavRefreshContentPhase { idle, exiting, placeholder }

mixin ScrollOrRefreshMixin {
  static const navRefreshExitDuration = Duration(milliseconds: 220);
  static const navTapFeedbackDuration = Duration(milliseconds: 504);
  static const navTapFeedbackTriggerDuration = Duration(milliseconds: 504);
  static const navTapFeedbackMaxOffset = 50.0;
  static const navTapFeedbackInitialProgress = 0.08;
  static const navTapFeedbackExitProgress = 3.0;
  static const navTapFeedbackMaxStretch = 0.18;

  ScrollController get scrollController;
  final Rx<NavRefreshContentPhase> navRefreshContentPhase =
      NavRefreshContentPhase.idle.obs;
  final RxDouble navTapFeedbackProgress = 0.0.obs;
  bool _isNavRefreshRunning = false;
  Timer? _navTapFeedbackTimer;
  int _navTapFeedbackStartedAt = 0;
  bool _isNavTapFeedbackRefreshTriggered = false;
  bool get isNavTapFeedbackRefreshTriggered =>
      _isNavTapFeedbackRefreshTriggered;

  void animateToTop() => scrollController.animToTop();

  void jumpToTop() => scrollController.jumpToTop();

  Future<void> onRefresh();

  void startNavTapFeedback({required VoidCallback onTriggerRefresh}) {
    if (_isNavRefreshRunning) return;
    _navTapFeedbackTimer?.cancel();
    _isNavTapFeedbackRefreshTriggered = false;
    _navTapFeedbackStartedAt = DateTime.now().millisecondsSinceEpoch;
    navTapFeedbackProgress.value = navTapFeedbackInitialProgress;
    _updateNavTapFeedback(onTriggerRefresh);
    _navTapFeedbackTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateNavTapFeedback(onTriggerRefresh),
    );
  }

  void _updateNavTapFeedback(VoidCallback onTriggerRefresh) {
    if (_isNavRefreshRunning) {
      cancelNavTapFeedback();
      return;
    }
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - _navTapFeedbackStartedAt;
    final progress =
        navTapFeedbackInitialProgress +
        elapsed /
            navTapFeedbackTriggerDuration.inMilliseconds *
            (1 - navTapFeedbackInitialProgress);
    navTapFeedbackProgress.value = progress
        .clamp(navTapFeedbackInitialProgress, 1.0)
        .toDouble();
    if (navTapFeedbackProgress.value >= 1.0 &&
        !_isNavTapFeedbackRefreshTriggered) {
      _isNavTapFeedbackRefreshTriggered = true;
      _navTapFeedbackTimer?.cancel();
      _navTapFeedbackTimer = null;
      onTriggerRefresh();
    }
  }

  void triggerNavTapFeedbackRefresh({required VoidCallback onTriggerRefresh}) {
    if (_isNavRefreshRunning || _isNavTapFeedbackRefreshTriggered) return;
    _isNavTapFeedbackRefreshTriggered = true;
    _navTapFeedbackTimer?.cancel();
    _navTapFeedbackTimer = null;
    navTapFeedbackProgress.value = 1.0;
    onTriggerRefresh();
  }

  void endNavTapFeedback() {
    if (_isNavTapFeedbackRefreshTriggered) return;
    cancelNavTapFeedback();
  }

  void cancelNavTapFeedback() {
    _navTapFeedbackTimer?.cancel();
    _navTapFeedbackTimer = null;
    _isNavTapFeedbackRefreshTriggered = false;
    navTapFeedbackProgress.value = 0.0;
  }

  Future<void> triggerNavRefresh() async {
    if (_isNavRefreshRunning) return;
    final useNavTapFeedbackExit = _isNavTapFeedbackRefreshTriggered;
    _isNavRefreshRunning = true;
    navRefreshContentPhase.value = NavRefreshContentPhase.exiting;

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (useNavTapFeedbackExit) {
      await _animateNavTapFeedbackExit();
    } else {
      await Future<void>.delayed(navRefreshExitDuration);
    }

    navRefreshContentPhase.value = NavRefreshContentPhase.placeholder;
    try {
      await onRefresh();
    } finally {
      cancelNavTapFeedback();
      navRefreshContentPhase.value = NavRefreshContentPhase.idle;
      _isNavRefreshRunning = false;
    }
  }

  Future<void> _animateNavTapFeedbackExit() async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    while (true) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      final progress = (elapsed / navRefreshExitDuration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      final exitProgress =
          1 +
          Curves.easeInCubic.transform(progress.toDouble()) *
              (navTapFeedbackExitProgress - 1);
      navTapFeedbackProgress.value = exitProgress;
      if (progress >= 1.0) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
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
    cancelNavTapFeedback();
    scrollController.dispose();
    super.onClose();
  }
}
