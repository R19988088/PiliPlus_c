import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('首页视频卡片复用现有封面角标样式', () {
    final vertical = File(
      'lib/common/widgets/video_card/video_card_v.dart',
    ).readAsStringSync();
    final horizontal = File(
      'lib/common/widgets/video_card/video_card_h.dart',
    ).readAsStringSync();

    for (final card in [vertical, horizontal]) {
      expect(card, contains('PBadge'));
      expect(card, contains('videoItem.coverBadge'));
      expect(card, contains('top: 6'));
      expect(card, contains('right: 6'));
      expect(card, contains("'充电专属'"));
      expect(card, contains('PBadgeType.error'));
    }
  });

  test('首页视频模型按个人页已有字段解析封面角标', () {
    final baseModel = File('lib/models/model_video.dart').readAsStringSync();
    final recommend = File(
      'lib/models/model_rec_video_item.dart',
    ).readAsStringSync();
    final recommendApp = File(
      'lib/models/home/rcmd/result.dart',
    ).readAsStringSync();
    final hot = File('lib/models/model_hot_video_item.dart').readAsStringSync();

    expect(baseModel, contains('String? coverBadge'));
    expect(baseModel, contains('setCoverBadgeFromJson'));
    expect(baseModel, contains('is_upower_exclusive'));
    expect(baseModel, contains('charging_pay'));
    expect(baseModel, contains('is_charging_arc'));
    expect(baseModel, contains('badges'));
    expect(baseModel, contains('is_ugcpay'));
    expect(baseModel, contains('ugc_pay'));
    expect(recommend, contains('setCoverBadgeFromJson(json)'));
    expect(recommendApp, contains('setCoverBadgeFromJson(json)'));
    expect(hot, contains('setCoverBadgeFromJson(json)'));
  });

  test('App 首页推荐用视频详情补齐充电专属角标', () {
    final videoHttp = File('lib/http/video.dart').readAsStringSync();

    expect(videoHttp, contains('_fillRcmdCoverBadges(list)'));
    expect(videoHttp, contains('Api.videoIntro'));
    expect(videoHttp, contains('item.setCoverBadgeFromJson'));
  });
}
