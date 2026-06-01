import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

enum NavRefreshContentPhase { idle, exiting, placeholder }

mixin ScrollOrRefreshMixin {
  static const navRefreshExitDuration = Duration(milliseconds: 220);

  ScrollController get scrollController;
  final Rx<NavRefreshContentPhase> navRefreshContentPhase =
      NavRefreshContentPhase.idle.obs;
  bool _isNavRefreshRunning = false;

  void animateToTop() => scrollController.animToTop();

  void jumpToTop() => scrollController.jumpToTop();

  Future<void> onRefresh();

  Future<void> triggerNavRefresh() async {
    if (_isNavRefreshRunning) return;
    _isNavRefreshRunning = true;
    navRefreshContentPhase.value = NavRefreshContentPhase.exiting;

    await Future<void>.delayed(const Duration(milliseconds: 16));
    jumpToTop();
    await Future<void>.delayed(navRefreshExitDuration);

    navRefreshContentPhase.value = NavRefreshContentPhase.placeholder;
    try {
      await onRefresh();
    } finally {
      navRefreshContentPhase.value = NavRefreshContentPhase.idle;
      _isNavRefreshRunning = false;
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
