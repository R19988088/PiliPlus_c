import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LaterBaseController extends GetxController with ScrollOrRefreshMixin {
  RxBool enableMultiSelect = false.obs;
  RxInt checkedCount = 0.obs;

  RxList<int> counts = List.filled(LaterViewType.values.length, -1).obs;
  ScrollOrRefreshMixin? activeController;
  ScrollController? _fallbackScrollController;

  @override
  ScrollController get scrollController =>
      activeController?.scrollController ??
      (_fallbackScrollController ??= ScrollController());

  @override
  Future<void> onRefresh() {
    return activeController?.onRefresh() ?? Future.syncValue(null);
  }

  late double dx = 0;
  late final RxBool isPlayAll = Pref.enablePlayAll.obs;

  void setIsPlayAll(bool isPlayAll) {
    if (this.isPlayAll.value == isPlayAll) return;
    this.isPlayAll.value = isPlayAll;
    GStorage.setting.put(SettingBoxKey.enablePlayAll, isPlayAll);
  }

  @override
  void onClose() {
    cancelNavTapFeedback();
    _fallbackScrollController?.dispose();
    super.onClose();
  }
}
