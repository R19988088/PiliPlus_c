import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('封面预览播放器自动取流播放并支持点击暂停继续', () {
    final player = File(
      'lib/common/widgets/video_preview/cover_preview_player.dart',
    ).readAsStringSync();

    expect(player, contains('Player.create'));
    expect(player, contains('VideoController.create'));
    expect(player, contains('VideoHttp.videoUrl'));
    expect(player, contains('SearchHttp.ab2cWithDimension'));
    expect(player, contains('play: true'));
    expect(player, contains('_escapeAudioUrl'));
    expect(player, contains('player.pause()'));
    expect(player, contains('player.play()'));
    expect(player, contains('SimpleVideo(controller: controller)'));
    expect(player, contains('Icons.pause_rounded'));
    expect(player, contains('Icons.play_arrow_rounded'));
  });
}
