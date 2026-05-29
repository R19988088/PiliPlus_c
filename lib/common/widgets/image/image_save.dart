import 'dart:ui';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/video_preview/cover_preview_player.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

void imageSaveDialog({
  required String? title,
  required String? cover,
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
                  child: CoverPreviewPlayer(
                    cover: cover,
                    width: imgWidth,
                    height: imgWidth / Style.aspectRatio16x9,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: SelectableText(
                        title,
                        style: theme.textTheme.titleSmall,
                      ),
                    )
                  else
                    const Spacer(),
                  if (aid != null || bvid != null)
                    iconButton(
                      iconSize: iconSize,
                      tooltip: '稍后再看',
                      onPressed: () => {
                        SmartDialog.dismiss(),
                        UserHttp.toViewLater(aid: aid, bvid: bvid),
                      },
                      icon: const Icon(Icons.watch_later_outlined),
                    ),
                  if (cover != null && cover.isNotEmpty) ...[
                    if (PlatformUtils.isMobile)
                      iconButton(
                        iconSize: iconSize,
                        tooltip: '分享',
                        onPressed: () {
                          SmartDialog.dismiss();
                          ImageUtils.onShareImg(cover);
                        },
                        icon: const Icon(Icons.share),
                      ),
                    iconButton(
                      iconSize: iconSize,
                      tooltip: '保存封面图',
                      onPressed: () async {
                        bool saveStatus = await ImageUtils.downloadImg([cover]);
                        if (saveStatus) {
                          SmartDialog.dismiss();
                        }
                      },
                      icon: const Icon(Icons.download),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
