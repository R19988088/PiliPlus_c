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
    expect(replyView, contains('buildGlassNavTint('));
    expect(replyView, contains('brightness: Pref.glassNavBlend'));
    expect(replyView, contains('lightIntensity: glassLightIntensity'));
    expect(replyView, contains('ambientStrength: glassAmbientStrength'));
    expect(replyView, isNot(contains('blend: glassBlend')));
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

    final timerIndex = headerControl.indexOf("message: '定时关闭'");
    final pipIndex = headerControl.indexOf("tooltip: '画中画'");
    expect(timerIndex, isNonNegative);
    expect(pipIndex, isNonNegative);
    expect(timerIndex, lessThan(pipIndex));
    expect(headerControl, contains('Icons.hourglass_top_outlined'));
    expect(headerControl, isNot(contains('Icons.schedule')));
    expect(headerControl, contains('ValueListenableBuilder<int>'));
    expect(headerControl, contains('shutdownTimerService.remainingSeconds'));
    expect(
      headerControl,
      contains('ShutdownTimerService.formatRemainingSeconds'),
    );
    expect(headerControl, contains('mainAxisSize: MainAxisSize.min'));
    expect(headerControl, contains('const SizedBox(width: 3)'));

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
    expect(shutdownTimer, contains('reset(duration);'));
    expect(shutdownTimer, contains('ValueNotifier<int> remainingSeconds'));
    expect(shutdownTimer, contains('Timer.periodic(const Duration(seconds: 1)'));
    expect(shutdownTimer, contains('formatRemainingSeconds'));
    expect(shutdownTimer, contains("'开始定时播放'"));
    expect(shutdownTimer, contains('_startShutdownTimer('));
    expect(shutdownTimer, contains('_durationInMinutes,'));
    expect(shutdownTimer, contains("'取消'"));
    expect(shutdownTimer, contains('Navigator.pop(context)'));
    expect(shutdownTimer, contains('mainAxisSize: MainAxisSize.min'));
    expect(shutdownTimer, contains('SingleChildScrollView('));
    expect(shutdownTimer, contains('elevation:'));
    expect(shutdownTimer, contains('shadowColor:'));
    expect(shutdownTimer, isNot(contains('showTimePicker(')));
    expect(shutdownTimer, isNot(contains("title: const Text('禁用'")));
    expect(shutdownTimer, isNot(contains("'关闭并关闭'")));
    expect(shutdownTimer, isNot(contains('_startShutdownTimer(0);')));
    expect(shutdownTimer, isNot(contains("child: Text('定时关闭'")));
    expect(shutdownTimer, isNot(contains("child: Text('定时关闭', style: titleStyle)")));
    expect(shutdownTimer, isNot(contains('return InkWell(')));
    expect(shutdownTimer, isNot(contains("return ListTile(\n                                dense: true,\n                                onTap: onChanged,")));
    expect(shutdownTimer, isNot(contains("title: const Text('自定义'")));
  });

  test('播放器全屏控制条只保留 5px 上下空位', () {
    final appBarAni = File(
      'lib/plugin/pl_player/widgets/app_bar_ani.dart',
    ).readAsStringSync();

    expect(appBarAni, contains('static const _fullScreenVerticalGap = 5.0;'));
    expect(appBarAni, contains('EdgeInsets.only('));
    expect(appBarAni, contains('top: isTop ? _fullScreenVerticalGap : 0.0'));
    expect(appBarAni, contains('bottom: isTop ? 0.0 : _fullScreenVerticalGap'));
    expect(appBarAni, contains('isFullScreen'));
    expect(appBarAni, contains('ViewSafeArea('));
  });

  test('播放器全屏控制条和隐藏进度条使用统一 120px 左右空白', () {
    final appBarAni = File(
      'lib/plugin/pl_player/widgets/app_bar_ani.dart',
    ).readAsStringSync();
    final bottomControl = File(
      'lib/plugin/pl_player/widgets/bottom_control.dart',
    ).readAsStringSync();
    final playerView = File(
      'lib/plugin/pl_player/view/view.dart',
    ).readAsStringSync();

    expect(
      appBarAni,
      contains('static const fullScreenHorizontalGap = 120.0;'),
    );
    expect(
      appBarAni,
      contains('EdgeInsets.symmetric(\n                  horizontal: fullScreenHorizontalGap,'),
    );
    expect(bottomControl, contains('isFullScreen ?'));
    expect(
      bottomControl,
      contains('const EdgeInsets.only(bottom: 12)'),
    );
    expect(
      bottomControl,
      contains('const EdgeInsets.only(bottom: 7)'),
    );
    expect(
      playerView,
      contains('left: isFullScreen ? AppBarAni.fullScreenHorizontalGap : 0'),
    );
    expect(
      playerView,
      contains('right: isFullScreen ? AppBarAni.fullScreenHorizontalGap : 0'),
    );
  });

  test('播放器支持设置全屏视频圆角裁切', () {
    final storageKey = File('lib/utils/storage_key.dart').readAsStringSync();
    final storagePref = File('lib/utils/storage_pref.dart').readAsStringSync();
    final playSettings = File(
      'lib/pages/setting/models/play_settings.dart',
    ).readAsStringSync();
    final playerView = File(
      'lib/plugin/pl_player/view/view.dart',
    ).readAsStringSync();
    final videoPageView = File('lib/pages/video/view.dart').readAsStringSync();

    expect(
      storageKey,
      contains(
        "fullscreenVideoRoundCornerRadius = 'fullscreenVideoRoundCornerRadius'",
      ),
    );
    expect(storagePref, contains('int get fullscreenVideoRoundCornerRadius'));
    expect(storagePref, contains('defaultValue: 10'));
    expect(playSettings, contains("title: '全屏圆角裁切'"));
    expect(playSettings, contains('min: 0.0'));
    expect(playSettings, contains('max: 20.0'));
    expect(playSettings, contains('suffix: \'px\''));
    expect(
      playSettings.indexOf("title: '全屏圆角裁切'"),
      lessThan(playSettings.indexOf("title: '倍速设置'")),
    );
    expect(videoPageView, contains('_fullscreenVideoClipRadius'));
    expect(videoPageView, contains('ClipRRect('));
    expect(videoPageView, contains('BorderRadius.circular('));
    expect(videoPageView, contains('Pref.fullscreenVideoRoundCornerRadius'));
    expect(videoPageView, contains('fullScreenClipRadius:'));
    expect(videoPageView, contains('.clamp(0, 20)'));
    expect(videoPageView, contains('return 0.0;'));
    expect(playerView, isNot(contains('Pref.fullscreenVideoRoundCornerRadius')));
    expect(playerView, contains('fullScreenClipRadius'));
    expect(playerView, contains('_clipActualVideoSurface'));
    expect(playerView, contains('final clippedChild = _clipPlayerViewport(child);'));
    expect(playerView, contains('child: clippedChild'));
    expect(playerView, contains('child: _clipActualVideoSurface('));
    expect(playerView, contains('return ClipRRect('));
    expect(playerView, contains('clipBehavior: Clip.hardEdge'));
  });

  test('非全屏非宽屏视频增加播放器高度', () {
    final videoPageView = File('lib/pages/video/view.dart').readAsStringSync();
    final videoController = File('lib/pages/video/controller.dart').readAsStringSync();
    final pageUtils = File('lib/utils/page_utils.dart').readAsStringSync();

    expect(videoPageView, contains('_kVerticalVideoExpandedHeightRatio = 0.72'));
    expect(videoPageView, contains('_nonFullscreenVideoHeight'));
    expect(videoPageView, contains('_shouldExpandNonFullscreenVideoHeight'));
    expect(videoPageView, contains('required double videoWidth'));
    expect(videoPageView, contains('clampDouble('));
    expect(videoPageView, contains('videoWidth / aspectRatio'));
    expect(videoPageView, contains('maxHeight * _kVerticalVideoExpandedHeightRatio'));
    expect(videoPageView, contains('size.longestSide * _kVerticalVideoExpandedHeightRatio'));
    expect(videoPageView, contains('maxHeight - videoHeight - padding.top'));
    expect(videoPageView, contains('_kNonFullscreenHeightExpandAspectRatio = 4 / 3'));
    expect(videoPageView, contains('return aspectRatio <= _kNonFullscreenHeightExpandAspectRatio'));
    expect(videoPageView, contains('videoAspectRatio: () => _videoAspectRatio'));
    expect(videoPageView, contains('double? get _videoAspectRatio'));
    expect(videoPageView, contains('Part? get _currentUgcPart'));
    expect(videoPageView, contains('_dimensionAspectRatio(_currentUgcPart?.dimension)'));
    expect(videoPageView, contains('_dimensionAspectRatio(videoDetailController.initialDimension)'));
    expect(videoPageView, contains('_dimensionAspectRatio(ugcIntroController.videoDetail.value.dimension)'));
    expect(videoController, contains('Dimension? initialDimension;'));
    expect(videoController, contains("initialDimension = args['dimension'];"));
    expect(pageUtils, contains("'dimension': ?dimension"));
    expect(playerView, contains('final double? Function()? videoAspectRatio;'));
    expect(playerView, contains('_resolvedVideoAspectRatio(videoFit)'));
    expect(playerView, contains('fit: videoFit.boxFit'));
    expect(playerView, isNot(contains('_resolvedVideoFit')));
    expect(playerView, isNot(contains('aspectRatio <= 1.5')));
    expect(playerView, contains('return widget.videoAspectRatio?.call()'));
  });
}
