import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('会员视频封面角标使用主题色压暗底色、描边和白字', () {
    final badge = File(
      'lib/common/widgets/video_card/vip_video_badge.dart',
    ).readAsStringSync();

    expect(badge, contains("'会员视频'"));
    expect(badge, contains('Color.alphaBlend'));
    expect(badge, contains('Colors.black.withValues(alpha: 0.8)'));
    expect(badge, contains('theme.primary'));
    expect(badge, contains('Border.all'));
    expect(badge, contains('Colors.white'));
  });

  test('横竖视频卡片在封面右上角显示会员视频角标', () {
    final vertical = File(
      'lib/common/widgets/video_card/video_card_v.dart',
    ).readAsStringSync();
    final horizontal = File(
      'lib/common/widgets/video_card/video_card_h.dart',
    ).readAsStringSync();

    for (final card in [vertical, horizontal]) {
      expect(card, contains('VipVideoBadge'));
      expect(card, contains('videoItem.isVipVideo'));
      expect(card, contains('top: 6'));
      expect(card, contains('right: 6'));
    }
  });

  test('视频模型解析会员视频字段', () {
    final baseModel = File('lib/models/model_video.dart').readAsStringSync();
    final recommend = File(
      'lib/models/model_rec_video_item.dart',
    ).readAsStringSync();
    final recommendApp = File(
      'lib/models/home/rcmd/result.dart',
    ).readAsStringSync();
    final hot = File('lib/models/model_hot_video_item.dart').readAsStringSync();

    expect(baseModel, contains('bool isVipVideo = false'));
    expect(baseModel, contains('is_ugcpay'));
    expect(baseModel, contains('ugc_pay'));
    expect(recommend, contains('setVipVideoFromJson(json)'));
    expect(recommendApp, contains('setVipVideoFromJson(json)'));
    expect(hot, contains('setVipVideoFromJson(json)'));
  });
}
