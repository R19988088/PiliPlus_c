import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('视频评论回复按钮固定显示并使用圆形液态玻璃样式', () {
    final replyView = File('lib/pages/video/reply/view.dart').readAsStringSync();

    expect(replyView, contains("common/widgets/liquid_glass_surface.dart"));
    expect(replyView, contains('LiquidGlassSurface('));
    expect(replyView, contains('shape: const CircleBorder()'));
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
