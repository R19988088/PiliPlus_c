import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_detail/media.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/pages/fav/video/controller.dart';
import 'package:PiliPlus/pages/fav_detail/widget/fav_video_card.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavVideoPage extends StatefulWidget {
  const FavVideoPage({super.key});

  @override
  State<FavVideoPage> createState() => _FavVideoPageState();
}

class _FavVideoPageState extends State<FavVideoPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  final FavController _favController = Get.find<FavController>();
  late final ScrollController _folderScrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _folderScrollController = ScrollController()
      ..addListener(_onFolderScroll);
  }

  @override
  void dispose() {
    _folderScrollController
      ..removeListener(_onFolderScroll)
      ..dispose();
    super.dispose();
  }

  void _onFolderScroll() {
    if (!_folderScrollController.hasClients) return;
    final position = _folderScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _favController.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _favController.onRefresh,
      child: CustomScrollView(
        controller: _favController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          Obx(() => _buildBody(_favController.loadingState.value)),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 100 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: Obx(
              () => _buildInlineDetailBody(
                Theme.of(context),
                _favController.inlineDetailController.loadingState.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavFolderInfo>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverPersistentHeader(
                pinned: true,
                delegate: _FolderStripHeaderDelegate(
                  folders: response,
                  selectedIndex: _favController.selectedFolderIndex.value,
                  folderScrollController: _folderScrollController,
                  onTap: _favController.selectFolder,
                ),
              )
            : HttpError(onReload: _favController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favController.onReload,
      ),
    };
  }

  Widget _buildInlineDetailBody(
    ThemeData theme,
    LoadingState<List<FavDetailItemModel>?> loadingState,
  ) {
    final ctr = _favController.inlineDetailController;
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length) {
                    ctr.onLoadMore();
                    return Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        ctr.isEnd ? '没有更多了' : '加载中...',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return FavVideoCardH(
                    item: response[index],
                    index: index,
                    ctr: ctr,
                  );
                },
                itemCount: response.length + 1,
              )
            : HttpError(onReload: ctr.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: ctr.onReload,
      ),
    };
  }
}

class _FolderStripHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FolderStripHeaderDelegate({
    required this.folders,
    required this.selectedIndex,
    required this.folderScrollController,
    required this.onTap,
  });

  final List<FavFolderInfo> folders;
  final int selectedIndex;
  final ScrollController folderScrollController;
  final void Function(int index, FavFolderInfo folder) onTap;

  @override
  double get minExtent => 150;

  @override
  double get maxExtent => 150;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: SingleChildScrollView(
          controller: folderScrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Style.safeSpace + padding.left,
            right: Style.safeSpace + padding.right,
            top: 9,
            bottom: 8,
          ),
          child: Row(
            spacing: 12,
            children: [
              for (final (index, item) in folders.indexed)
                _FolderCoverItem(
                  item: item,
                  selected: selectedIndex == index,
                  onTap: () => onTap(index, item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FolderStripHeaderDelegate oldDelegate) {
    return folders != oldDelegate.folders ||
        selectedIndex != oldDelegate.selectedIndex;
  }
}

class _FolderCoverItem extends StatelessWidget {
  const _FolderCoverItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FavFolderInfo item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: 150,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: Style.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        NetworkImgLayer(
                          src: item.cover,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              BiliUtils.isPublicFav(item.attr)
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : null,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
                Text(
                  '${item.mediaCount}个内容',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: theme.textTheme.labelMedium!.fontSize,
                    color: colorScheme.outline,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(top: 5),
                  height: 3,
                  width: selected ? 72 : 0,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
