import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('视频评论回复按钮固定显示并使用圆形液态玻璃样式', () {
    final replyView = File('lib/pages/video/reply/view.dart').readAsStringSync();

    expect(
      replyView,
      contains('package:liquid_glass_widgets/liquid_glass_widgets.dart'),
    );
    expect(replyView, contains('utils/extension/theme_ext.dart'));
    expect(replyView, contains('utils/storage_pref.dart'));
    expect(
      replyView,
      contains('const _kReplyButtonGlassDefaults = LiquidGlassSettings'),
    );
    expect(replyView, contains('GlassContainer('));
    expect(replyView, contains('LiquidRoundedSuperellipse('));
    expect(replyView, contains('settings: _kReplyButtonGlassDefaults.copyWith'));
    expect(replyView, contains('Pref.glassNavOpacity.clamp(0, 100) / 100'));
    expect(replyView, contains('Pref.glassNavBlur.clamp(0, 100) / 10'));
    expect(
      replyView,
      contains('Pref.glassNavThickness.clamp(0, 100).toDouble()'),
    );
    expect(
      replyView,
      contains('Pref.glassNavChromaticAberration.clamp(0, 200) / 100'),
    );
    expect(
      replyView,
      contains('Pref.glassNavRefraction.clamp(0, 100) * 0.0118'),
    );
    expect(replyView, contains('Pref.glassNavBlend.clamp(0, 100) / 100'));
    expect(replyView, contains('SizedBox.square('));
    expect(replyView, contains('Icons.reply'));
    expect(replyView, isNot(contains('hideFab()')));
    expect(replyView, isNot(contains('SlideTransition(')));
    expect(replyView, isNot(contains('with\n        AutomaticKeepAliveClientMixin,\n        SingleTickerProviderStateMixin,\n        FabMixin')));
  });

  test('UGC 简介标题排在作者信息前面', () {
    final introView = File(
      'lib/pages/video/introduction/ugc/view.dart',
    ).readAsStringSync();

    final titleIndex = introView.indexOf(
      'if (isLoading)\n                    _buildVideoTitle(theme, videoDetail)',
    );
    final authorIndex = introView.indexOf(
      'if (videoDetail.staff.isNullOrEmpty) ...[',
    );

    expect(titleIndex, isNonNegative);
    expect(authorIndex, isNonNegative);
    expect(titleIndex, lessThan(authorIndex));
    expect(
      introView,
      contains(r"'/member?mid=$mid&from_view_aid=${videoDetailCtr.aid}'"),
    );
  });
}
