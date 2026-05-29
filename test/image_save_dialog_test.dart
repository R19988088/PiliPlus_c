import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('封面长按弹窗启用轻微背景模糊并允许点击空白关闭', () {
    final imageSaveDialog = File(
      'lib/common/widgets/image/image_save.dart',
    ).readAsStringSync();

    expect(imageSaveDialog, contains('clickMaskDismiss: true'));
    expect(imageSaveDialog, contains('usePenetrate: false'));
    expect(imageSaveDialog, contains('maskWidget:'));
    expect(imageSaveDialog, contains('BackdropFilter'));
    expect(imageSaveDialog, contains('ImageFilter.blur'));
    expect(imageSaveDialog, contains('sigmaX: 2.0'));
    expect(imageSaveDialog, contains('sigmaY: 2.0'));
    expect(imageSaveDialog, contains('boxShadow:'));
    expect(imageSaveDialog, contains('CoverPreviewPlayer'));
    expect(imageSaveDialog, contains('face'));
    expect(imageSaveDialog, contains('NetworkImgLayer'));
    expect(imageSaveDialog, contains('ImageType.avatar'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.thumbsUp'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.thumbsDown'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.b'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.star'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.clock'));
    expect(imageSaveDialog, contains('FontAwesomeIcons.shareFromSquare'));
    expect(imageSaveDialog, contains('Icons.download'));
    expect(imageSaveDialog, contains('PageUtils.toVideoPage'));
    expect(imageSaveDialog, contains('SearchHttp.ab2cWithDimension'));
    expect(imageSaveDialog, contains('_CoverPreviewSurface'));
    expect(imageSaveDialog, contains('ImageStreamListener'));
    expect(imageSaveDialog, contains('_calcCoverHeight'));
    expect(imageSaveDialog, contains('_fallbackAspectRatio'));
    expect(imageSaveDialog, contains('aid: aid'));
    expect(imageSaveDialog, contains('bvid: bvid'));
    expect(imageSaveDialog, contains('cid: cid'));
    expect(imageSaveDialog, isNot(contains('onTap: SmartDialog.dismiss')));
  });

  test('首页和动态封面长按弹窗传入头像', () {
    final videoCardV = File(
      'lib/common/widgets/video_card/video_card_v.dart',
    ).readAsStringSync();
    final videoCardH = File(
      'lib/common/widgets/video_card/video_card_h.dart',
    ).readAsStringSync();
    final dynamicPanel = File(
      'lib/pages/dynamics/widgets/dynamic_panel.dart',
    ).readAsStringSync();
    final forwardPanel = File(
      'lib/pages/dynamics/widgets/forward_panel.dart',
    ).readAsStringSync();

    expect(videoCardV, contains('face:'));
    expect(videoCardH, contains('face:'));
    expect(dynamicPanel, contains('moduleAuthor?.face'));
    expect(forwardPanel, contains('moduleAuthor?.face'));
  });
}
