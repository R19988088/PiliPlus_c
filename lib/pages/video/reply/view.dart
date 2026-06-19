import 'package:PiliPlus/common/skeleton/video_reply.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/glass_nav_tint.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/video/reply/controller.dart';
import 'package:PiliPlus/pages/video/reply/widgets/reply_item_grpc.dart';
import 'package:PiliPlus/pages/video/reply_reply/view.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _kReplyButtonGlassDefaults = LiquidGlassSettings(
  lightIntensity: 0.6,
  saturation: 0.7,
  ambientStrength: 1,
  lightAngle: 2.356194490192345,
);

class VideoReplyPanel extends StatefulWidget {
  const VideoReplyPanel({
    super.key,
    this.replyLevel = 1,
    required this.heroTag,
    required this.isNested,
  });

  final int replyLevel;
  final String heroTag;
  final bool isNested;

  @override
  State<VideoReplyPanel> createState() => _VideoReplyPanelState();
}

class _VideoReplyPanelState extends State<VideoReplyPanel>
    with AutomaticKeepAliveClientMixin {
  late VideoReplyController _videoReplyController;

  String get heroTag => widget.heroTag;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _videoReplyController = Get.find<VideoReplyController>(tag: heroTag);
    if (_videoReplyController.loadingState.value is Loading) {
      _videoReplyController.queryData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bottom = MediaQuery.viewPaddingOf(context).bottom;
  }

  late double bottom;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = colorScheme.brightness.isLight;
    final navUsesLightDefinition = Pref.inverseNavigationBar
        ? !isLight
        : isLight;
    final navTint = buildGlassNavTint(
      primary: colorScheme.primary,
      navUsesLightDefinition: navUsesLightDefinition,
      saturationMin: Pref.glassNavSaturationMin,
      saturationMax: Pref.glassNavSaturationMax,
      lightnessLight: Pref.glassNavLightnessLight,
      lightnessDark: Pref.glassNavLightnessDark,
      brightness: Pref.glassNavBlend,
      opacity: Pref.glassNavOpacity,
    );
    final glassLightIntensity = glassNavLightIntensityForBrightness(
      Pref.glassNavBlend,
    );
    final glassAmbientStrength = glassNavAmbientStrengthForBrightness(
      Pref.glassNavBlend,
    );
    final glassBlur = Pref.glassNavBlur.clamp(0, 100) / 10;
    final glassLensRadius = Pref.glassNavThickness.clamp(0, 100).toDouble();
    final chromaticAberration =
        Pref.glassNavChromaticAberration.clamp(0, 200) / 100;
    final refractiveIndex = 1 + Pref.glassNavRefraction.clamp(0, 100) * 0.0118;
    final iconColor = navUsesLightDefinition ? Colors.black : Colors.white;
    final buttonShadowColor = isLight
        ? colorScheme.primary.darken(0.84).withValues(alpha: 0.26)
        : Colors.black.withValues(alpha: 0.44);
    final child = refreshIndicator(
      onRefresh: _videoReplyController.onRefresh,
      isClampingScrollPhysics: widget.isNested,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomScrollView(
            controller: widget.isNested
                ? null
                : _videoReplyController.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            key: const PageStorageKey(_VideoReplyPanelState),
            slivers: [
              SliverFloatingHeaderWidget(
                backgroundColor: theme.colorScheme.surface,
                child: Padding(
                  padding: const .fromLTRB(12, 2.5, 6, 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(
                        () => Text(
                          _videoReplyController.sortType.value.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        style: Style.buttonStyle,
                        onPressed: _videoReplyController.queryBySort,
                        icon: Icon(
                          Icons.sort,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        label: Obx(
                          () => Text(
                            _videoReplyController.sortType.value.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => _buildBody(
                  theme,
                  _videoReplyController.loadingState.value,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Padding(
              padding: .only(
                right: kFloatingActionButtonMargin,
                bottom: kFloatingActionButtonMargin + bottom,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonShadowColor,
                      blurRadius: 30,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: GlassContainer(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 30),
                  settings: _kReplyButtonGlassDefaults.copyWith(
                    glassColor: navTint,
                    lightIntensity: glassLightIntensity,
                    ambientStrength: glassAmbientStrength,
                    thickness: glassLensRadius,
                    blur: glassBlur,
                    chromaticAberration: chromaticAberration,
                    refractiveIndex: refractiveIndex,
                  ),
                  quality: GlassQuality.premium,
                  useOwnLayer: true,
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.square(
                    dimension: 60,
                    child: IconButton(
                      onPressed: () {
                        feedBack();
                        _videoReplyController.onReply(
                          null,
                          oid: _videoReplyController.aid,
                          replyType: _videoReplyController.videoType.replyType,
                        );
                      },
                      tooltip: '发表评论',
                      icon: Icon(
                        Icons.reply,
                        size: 27,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.isNested) {
      return ExtendedVisibilityDetector(
        uniqueKey: const Key('reply-list'),
        child: child,
      );
    }
    return child;
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<ReplyInfo>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => SliverList.builder(
        itemBuilder: (context, index) => const VideoReplySkeleton(),
        itemCount: 5,
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.builder(
                itemBuilder: (context, index) {
                  if (index == response.length) {
                    _videoReplyController.onLoadMore();
                    return Container(
                      height: 125,
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: bottom),
                      child: Text(
                        _videoReplyController.isEnd ? '没有更多了' : '加载中...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  } else {
                    return ReplyItemGrpc(
                      replyItem: response[index],
                      replyLevel: widget.replyLevel,
                      replyReply: replyReply,
                      onReply: _videoReplyController.onReply,
                      onDelete: (item, subIndex) =>
                          _videoReplyController.onRemove(index, item, subIndex),
                      upMid: _videoReplyController.upMid,
                      getTag: () => heroTag,
                      onCheckReply: (item) => _videoReplyController
                          .onCheckReply(item, isManual: true),
                      onToggleTop: (item) => _videoReplyController.onToggleTop(
                        item,
                        index,
                        _videoReplyController.aid,
                        _videoReplyController.videoType.replyType,
                      ),
                    );
                  }
                },
                itemCount: response.length + 1,
              )
            : HttpError(
                errMsg: '还没有评论',
                onReload: _videoReplyController.onReload,
              ),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _videoReplyController.onReload,
      ),
    };
  }

  // 展示二级回复
  void replyReply(ReplyInfo replyItem, int? id) {
    EasyThrottle.throttle('replyReply', const Duration(milliseconds: 500), () {
      int oid = replyItem.oid.toInt();
      int rpid = replyItem.id.toInt();
      Scaffold.of(context).showBottomSheet(
        backgroundColor: Colors.transparent,
        constraints: const BoxConstraints(),
        (context) => VideoReplyReplyPanel(
          id: id,
          oid: oid,
          rpid: rpid,
          firstFloor: replyItem.replyControl.isNote ? null : replyItem,
          replyType: _videoReplyController.videoType.replyType,
          isVideoDetail: true,
          isNested: widget.isNested,
          upMid: _videoReplyController.upMid,
        ),
      );
    });
  }
}
