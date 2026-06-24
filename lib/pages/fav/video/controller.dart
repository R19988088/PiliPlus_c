import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/fav_detail/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class FavController extends CommonListController<FavFolderData, FavFolderInfo> {
  late final account = Accounts.main;
  final RxInt selectedFolderIndex = 0.obs;
  final Map<int, double> folderScrollOffsets = <int, double>{};
  late final InlineFavDetailController inlineDetailController =
      Get.put(InlineFavDetailController(this));

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<void> queryData([bool isRefresh = true]) {
    if (!account.isLogin) {
      loadingState.value = const Error('账号未登录');
      return Future.syncValue(null);
    }
    return super.queryData(isRefresh);
  }

  @override
  List<FavFolderInfo>? getDataList(FavFolderData response) {
    if (response.hasMore == false) {
      isEnd = true;
    }
    return response.list;
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<FavFolderData> response) {
    final list = response.response.list;
    if (isRefresh && list != null && list.isNotEmpty) {
      final selectedMediaId = inlineDetailController.mediaId;
      var index = list.indexWhere((item) => item.id == selectedMediaId);
      if (index < 0) {
        index = 0;
      }
      selectedFolderIndex.value = index;
      inlineDetailController.bindFolder(
        list[index],
        restoreOffset: folderScrollOffsets[list[index].id] ?? 0,
      );
    }
    return false;
  }

  void selectFolder(int index, FavFolderInfo folder) {
    if (selectedFolderIndex.value == index &&
        inlineDetailController.mediaId == folder.id) {
      return;
    }
    saveCurrentFolderOffset();
    selectedFolderIndex.value = index;
    inlineDetailController.bindFolder(
      folder,
      restoreOffset: folderScrollOffsets[folder.id] ?? 0,
    );
  }

  void saveCurrentFolderOffset() {
    if (!scrollController.hasClients) return;
    folderScrollOffsets[inlineDetailController.mediaId] =
        scrollController.offset;
  }

  void restoreFolderOffset(int mediaId) {
    final offset = folderScrollOffsets[mediaId] ?? 0;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final max = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(offset.clamp(0, max).toDouble());
    });
  }

  @override
  Future<LoadingState<FavFolderData>> customGetData() => FavHttp.userfavFolder(
    pn: page,
    ps: 20,
    mid: account.mid,
  );
}

class InlineFavDetailController extends FavDetailController {
  InlineFavDetailController(this.favController);

  final FavController favController;
  final RxBool _inlineIsOwner = false.obs;
  double? _pendingRestoreOffset;

  @override
  bool get isOwner => _inlineIsOwner.value;

  @override
  void onInit() {
    // Folder data is supplied by FavController.selectFolder.
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<FavDetailData> response) {
    final handled = super.customHandleResponse(isRefresh, response);
    if (isRefresh && _pendingRestoreOffset != null) {
      final offset = _pendingRestoreOffset!;
      _pendingRestoreOffset = null;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!favController.scrollController.hasClients) return;
        final max = favController.scrollController.position.maxScrollExtent;
        favController.scrollController.jumpTo(offset.clamp(0, max).toDouble());
      });
    }
    return handled;
  }

  void bindFolder(FavFolderInfo folder, {double restoreOffset = 0}) {
    mediaId = folder.id;
    heroTag = 'fav-inline-${folder.fid ?? folder.id}';
    folderInfo.value = folder;
    _inlineIsOwner.value = folder.mid == account.mid;
    _pendingRestoreOffset = restoreOffset;
    onReload();
  }
}
