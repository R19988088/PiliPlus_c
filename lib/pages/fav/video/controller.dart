import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/fav_detail/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:get/get.dart';

class FavController extends CommonListController<FavFolderData, FavFolderInfo> {
  late final account = Accounts.main;
  final RxInt selectedFolderIndex = 0.obs;
  late final InlineFavDetailController inlineDetailController =
      Get.put(InlineFavDetailController());

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
      selectedFolderIndex.value = 0;
      inlineDetailController.bindFolder(list.first);
    }
    return false;
  }

  void selectFolder(int index, FavFolderInfo folder) {
    if (selectedFolderIndex.value == index &&
        inlineDetailController.mediaId == folder.id) {
      return;
    }
    selectedFolderIndex.value = index;
    inlineDetailController.bindFolder(folder);
  }

  @override
  Future<LoadingState<FavFolderData>> customGetData() => FavHttp.userfavFolder(
    pn: page,
    ps: 20,
    mid: account.mid,
  );
}

class InlineFavDetailController extends FavDetailController {
  final RxBool _inlineIsOwner = false.obs;

  @override
  bool get isOwner => _inlineIsOwner.value;

  @override
  void onInit() {
    // Folder data is supplied by FavController.selectFolder.
  }

  void bindFolder(FavFolderInfo folder) {
    mediaId = folder.id;
    heroTag = 'fav-inline-${folder.fid ?? folder.id}';
    folderInfo.value = folder;
    _inlineIsOwner.value = folder.mid == account.mid;
    onReload();
  }
}
