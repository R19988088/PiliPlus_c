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

  test('视频顶部控制栏移除主页和弹幕开关并直达定时关闭', () {
    final headerControl = File(
      'lib/pages/video/widgets/header_control.dart',
    ).readAsStringSync();

    expect(headerControl, isNot(contains("tooltip: '返回主页'")));
    expect(headerControl, isNot(contains('FontAwesomeIcons.house')));
    expect(headerControl, isNot(contains("tooltip: '弹幕设置'")));
    expect(
      headerControl,
      contains("title: const Text('弹幕设置', style: titleStyle)"),
    );
    expect(
      headerControl,
      isNot(
        contains("tooltip: \"\${enableShowDanmaku ? '关闭' : '开启'}弹幕\""),
      ),
    );

    final timerIndex = headerControl.indexOf("tooltip: '定时关闭'");
    final pipIndex = headerControl.indexOf("tooltip: '画中画'");
    expect(timerIndex, isNonNegative);
    expect(pipIndex, isNonNegative);
    expect(timerIndex, lessThan(pipIndex));
    expect(headerControl, contains('Icons.hourglass_top_outlined'));
    expect(headerControl, isNot(contains('Icons.schedule')));

    expect(
      headerControl,
      isNot(contains("title: const Text('定时关闭', style: titleStyle)")),
    );
  });

  test('UGC 简介标题间距增大且超过三行才折叠', () {
    final introView = File(
      'lib/pages/video/introduction/ugc/view.dart',
    ).readAsStringSync();

    expect(introView, contains('const _kTitleVerticalSpacing = 10.4;'));
    expect(introView, contains('maxLines: isExpand ? null : 3'));
  });

  test('定时关闭面板直接显示自定义时间滑动选择器', () {
    final shutdownTimer = File(
      'lib/services/shutdown_timer_service.dart',
    ).readAsStringSync();

    expect(shutdownTimer, contains('_buildInlineTimePicker'));
    expect(shutdownTimer, contains('onVerticalDragUpdate'));
    expect(shutdownTimer, contains('_adjustCustomDuration('));
    expect(shutdownTimer, contains('hours: isHour ? direction : 0'));
    expect(shutdownTimer, contains('minutes: isHour ? 0 : direction'));
    expect(shutdownTimer, contains('hours * 60'));
    expect(shutdownTimer, contains('minutes * 15'));
    expect(shutdownTimer, contains("'关闭并关闭'"));
    expect(shutdownTimer, contains('Navigator.pop(context)'));
    expect(shutdownTimer, contains('mainAxisSize: MainAxisSize.min'));
    expect(shutdownTimer, contains('SingleChildScrollView('));
    expect(shutdownTimer, contains('elevation:'));
    expect(shutdownTimer, contains('shadowColor:'));
    expect(shutdownTimer, isNot(contains('showTimePicker(')));
    expect(shutdownTimer, isNot(contains("title: const Text('禁用'")));
    expect(shutdownTimer, isNot(contains('_startShutdownTimer(0);')));
    expect(shutdownTimer, isNot(contains("title: const Text('自定义'")));
  });
}
