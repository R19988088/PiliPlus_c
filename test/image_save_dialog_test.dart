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
    expect(imageSaveDialog, contains('ValueNotifier<bool>'));
    expect(imageSaveDialog, contains('onDismiss: isPlaying.dispose'));
    expect(imageSaveDialog, contains('Icons.pause_rounded'));
    expect(imageSaveDialog, contains('Icons.play_arrow_rounded'));
    expect(imageSaveDialog, isNot(contains('onTap: SmartDialog.dismiss')));
  });
}
