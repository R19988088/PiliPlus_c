import 'dart:ui';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/video_preview/cover_preview_player.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/share_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

void imageSaveDialog({
  required String? title,
  required String? cover,
  String? face,
  dynamic aid,
  String? bvid,
  int? cid,
}) {
  final double imgWidth = MediaQuery.sizeOf(Get.context!).shortestSide - 16;
  SmartDialog.show(
    animationType: SmartAnimationType.centerScale_otherSlide,
    clickMaskDismiss: true,
    usePenetrate: false,
    maskWidget: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.18),
        child: const SizedBox.expand(),
      ),
    ),
    builder: (context) {
      const iconSize = 20.0;
      final theme = Theme.of(context);
      final canOpenVideo = aid != null || bvid?.isNotEmpty == true;
      return Container(
        width: imgWidth,
        margin: const .symmetric(horizontal: Style.safeSpace),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: Style.mdRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const .vertical(top: Style.imgRadius),
                  child: _CoverPreviewSurface(
                    cover: cover,
                    width: imgWidth,
                    aid: aid,
                    bvid: bvid,
                    cid: cid,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  width: 30,
                  height: 30,
                  child: IconButton(
                    tooltip: '关闭',
                    style: IconButton.styleFrom(
                      padding: .zero,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: SmartDialog.dismiss,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NetworkImgLayer(
                        src: face,
                        width: 58,
                        height: 58,
                        type: ImageType.avatar,
                      ),
                      const SizedBox(width: 16),
                      if (title != null)
                        Expanded(
                          child: SelectableText(
                            title,
                            maxLines: 3,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '点赞',
                        icon: const Icon(FontAwesomeIcons.thumbsUp),
                        onPressed: canOpenVideo
                            ? () => _openVideoDetail(
                                aid: aid,
                                bvid: bvid,
                                cid: cid,
                                cover: cover,
                                title: title,
                              )
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '点踩',
                        icon: const Icon(FontAwesomeIcons.thumbsDown),
                        onPressed: canOpenVideo
                            ? () => _openVideoDetail(
                                aid: aid,
                                bvid: bvid,
                                cid: cid,
                                cover: cover,
                                title: title,
                              )
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '投币',
                        icon: const Icon(FontAwesomeIcons.b),
                        onPressed: canOpenVideo
                            ? () => _openVideoDetail(
                                aid: aid,
                                bvid: bvid,
                                cid: cid,
                                cover: cover,
                                title: title,
                              )
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '收藏',
                        icon: const Icon(FontAwesomeIcons.star),
                        onPressed: canOpenVideo
                            ? () => _openVideoDetail(
                                aid: aid,
                                bvid: bvid,
                                cid: cid,
                                cover: cover,
                                title: title,
                              )
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '稍后再看',
                        icon: const Icon(FontAwesomeIcons.clock),
                        onPressed: aid != null || bvid != null
                            ? () => {
                                SmartDialog.dismiss(),
                                UserHttp.toViewLater(aid: aid, bvid: bvid),
                              }
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '分享',
                        icon: const Icon(FontAwesomeIcons.shareFromSquare),
                        onPressed:
                            bvid?.isNotEmpty == true ||
                                (cover?.isNotEmpty == true &&
                                    PlatformUtils.isMobile)
                            ? () {
                                if (bvid?.isNotEmpty == true) {
                                  SmartDialog.dismiss();
                                  ShareUtils.shareText(
                                    '${title ?? ''} https://www.bilibili.com/video/$bvid',
                                  );
                                  return;
                                }
                                SmartDialog.dismiss();
                                ImageUtils.onShareImg(cover!);
                              }
                            : null,
                      ),
                      _PreviewActionButton(
                        iconSize: iconSize,
                        tooltip: '保存封面图',
                        icon: const Icon(Icons.download),
                        onPressed: cover?.isNotEmpty == true
                            ? () async {
                                bool saveStatus = await ImageUtils.downloadImg([
                                  cover!,
                                ]);
                                if (saveStatus) {
                                  SmartDialog.dismiss();
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CoverPreviewSurface extends StatefulWidget {
  const _CoverPreviewSurface({
    required this.cover,
    required this.width,
    required this.aid,
    required this.bvid,
    required this.cid,
  });

  final String? cover;
  final double width;
  final dynamic aid;
  final String? bvid;
  final int? cid;

  @override
  State<_CoverPreviewSurface> createState() => _CoverPreviewSurfaceState();
}

class _CoverPreviewSurfaceState extends State<_CoverPreviewSurface> {
  static const double _fallbackAspectRatio = Style.aspectRatio16x9;
  Size? _imageSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _resolveCoverSize();
  }

  @override
  void didUpdateWidget(_CoverPreviewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cover != widget.cover) {
      _imageSize = null;
      _resolveCoverSize();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveCoverSize() {
    _removeImageListener();
    final cover = widget.cover;
    if (cover == null || cover.isEmpty) {
      return;
    }
    final provider = CachedNetworkImageProvider(
      ImageUtils.thumbnailUrl(cover, 100),
    );
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (mounted) {
          setState(() => _imageSize = size);
        }
        stream.removeListener(listener);
        if (identical(_imageStream, stream)) {
          _imageStream = null;
          _imageListener = null;
        }
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (identical(_imageStream, stream)) {
          _imageStream = null;
          _imageListener = null;
        }
      },
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _imageListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageListener = null;
  }

  double _calcCoverHeight() {
    final size = _imageSize;
    final aspectRatio = size == null || size.width <= 0 || size.height <= 0
        ? _fallbackAspectRatio
        : size.width / size.height;
    return widget.width / aspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    final height = _calcCoverHeight();
    return CoverPreviewPlayer(
      cover: widget.cover,
      width: widget.width,
      height: height,
      aid: widget.aid,
      bvid: widget.bvid,
      cid: widget.cid,
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.iconSize,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return iconButton(
      iconSize: iconSize,
      size: 32,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

Future<void> _openVideoDetail({
  required dynamic aid,
  required String? bvid,
  required int? cid,
  required String? cover,
  required String? title,
}) async {
  if (aid == null && bvid?.isNotEmpty != true) {
    return;
  }
  SmartDialog.dismiss();
  int? targetCid = cid;
  Dimension? dimension;
  if (targetCid == null) {
    if (await SearchHttp.ab2cWithDimension(aid: aid, bvid: bvid)
        case final res?) {
      targetCid = res.cid;
      dimension = res.dimension;
    }
  }
  if (targetCid != null) {
    PageUtils.toVideoPage(
      aid: aid,
      bvid: bvid,
      cid: targetCid,
      cover: cover,
      title: title,
      dimension: dimension,
    );
  }
}
