import 'dart:io';

import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
import 'package:PiliPlus/pages/setting/models/video_settings.dart';
import 'package:PiliPlus/plugin/pl_player/utils/bluetooth_audio_delay.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

String functionBody(String source, String signature) {
  final signatureStart = source.indexOf(signature);
  expect(signatureStart, isNonNegative);

  var parenDepth = 0;
  var signatureEnd = -1;
  for (var i = signatureStart; i < source.length; i++) {
    final codeUnit = source.codeUnitAt(i);
    if (codeUnit == 40) {
      parenDepth++;
    } else if (codeUnit == 41) {
      parenDepth--;
      if (parenDepth == 0) {
        signatureEnd = i;
        break;
      }
    }
  }
  expect(signatureEnd, isNonNegative);

  final bodyStart = source.indexOf('{', signatureEnd);
  expect(bodyStart, isNonNegative);

  var depth = 0;
  for (var i = bodyStart; i < source.length; i++) {
    final codeUnit = source.codeUnitAt(i);
    if (codeUnit == 123) {
      depth++;
    } else if (codeUnit == 125) {
      depth--;
      if (depth == 0) {
        return source.substring(bodyStart, i + 1);
      }
    }
  }

  fail('Could not find function body for $signature');
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pili_plus_test_');
    Hive.init(tempDir.path);
    GStorage.setting = await Hive.openBox('setting');
  });

  tearDownAll(() async {
    await GStorage.setting.close();
    await tempDir.delete(recursive: true);
  });

  test('后台播放默认开启，锁屏或切后台时不自动暂停', () {
    expect(Pref.continuePlayInBackground, isTrue);
  });

  test('播放设置页后台播放开关默认开启', () {
    final setting = playSettings.whereType<SwitchModel>().singleWhere(
      (item) => item.setKey == SettingBoxKey.continuePlayInBackground,
    );

    expect(setting.defaultVal, isTrue);
  });

  test('自动连播完成事件同步到后台媒体服务，避免锁屏通知停在旧状态', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(playerController, contains('void _notifyPlaybackCompleted()'));

    final completedListenerStart = playerController.indexOf(
      'stream.completed.listen((event) {',
    );
    final positionListenerStart = playerController.indexOf(
      'stream.position.listen((event) {',
    );
    expect(completedListenerStart, isNonNegative);
    expect(positionListenerStart, greaterThan(completedListenerStart));

    final completedListener = playerController.substring(
      completedListenerStart,
      positionListenerStart,
    );
    expect(
      functionBody(playerController, 'void _notifyPlaybackCompleted()'),
      contains('videoPlayerServiceHandler?.onStatusChange('),
    );
    expect(
      functionBody(
        playerController,
        'void _notifyPlaybackCompleted()',
      ).indexOf('playerStatus.value = PlayerStatus.completed'),
      lessThan(
        functionBody(
          playerController,
          'void _notifyPlaybackCompleted()',
        ).indexOf('videoPlayerServiceHandler?.onStatusChange('),
      ),
    );
    expect(
      functionBody(
        playerController,
        'void _notifyPlaybackCompleted()',
      ).indexOf('videoPlayerServiceHandler?.onStatusChange('),
      lessThan(
        functionBody(
          playerController,
          'void _notifyPlaybackCompleted()',
        ).indexOf('for (final element in _statusListeners)'),
      ),
    );
    expect(completedListener, contains('_notifyPlaybackCompleted();'));
  });

  test('底层完成事件缺失时，进度到达结尾也会合成完成状态触发连播', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final positionListenerStart = playerController.indexOf(
      'stream.position.listen((event) {',
    );
    final durationListenerStart = playerController.indexOf(
      'stream.duration.listen((Duration event) {',
    );
    expect(positionListenerStart, isNonNegative);
    expect(durationListenerStart, greaterThan(positionListenerStart));

    final positionListener = playerController.substring(
      positionListenerStart,
      durationListenerStart,
    );
    expect(
      positionListener,
      contains('if (_shouldSynthesizeCompletedFromPosition) {'),
    );
    expect(positionListener, contains('_notifyPlaybackCompleted();'));
    expect(playerController, contains('!isSliderMoving.value &&'));
    expect(
      positionListener.indexOf('updatePositionSecond();'),
      lessThan(
        positionListener.indexOf(
          'if (_shouldSynthesizeCompletedFromPosition) {',
        ),
      ),
    );
  });

  test('接近结尾的缓冲停滞不刷新当前源，避免错误时间跳转阻断连播', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final watchdog = functionBody(
      playerController,
      'void _checkBufferWatchdog()',
    );
    expect(playerController, contains('bool get _isInPlaybackEndRefreshWindow'));
    expect(watchdog, contains('if (_isInPlaybackEndRefreshWindow) {'));
    expect(watchdog, contains('_notifyPlaybackCompleted();'));
    expect(
      watchdog.indexOf('if (_isInPlaybackEndRefreshWindow) {'),
      lessThan(watchdog.indexOf('final refresh = refreshPlayer();')),
    );
  });

  test('中途误报完成不会触发自动连播，而是重试当前视频', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final nearEndGetterStart = playerController.indexOf(
      'bool get _isNearPlaybackEnd {',
    );
    final instanceGetterStart = playerController.indexOf(
      'static PlPlayerController? get instance => _instance;',
    );
    expect(nearEndGetterStart, isNonNegative);
    expect(instanceGetterStart, greaterThan(nearEndGetterStart));

    final nearEndGetter = playerController.substring(
      nearEndGetterStart,
      instanceGetterStart,
    );
    expect(
      nearEndGetter,
      contains('final effectivePosition = position > Duration.zero'),
    );
    expect(nearEndGetter, contains(': _lastValidPosition;'));
    expect(nearEndGetter, contains('return effectivePosition > Duration.zero;'));

    final completedListenerStart = playerController.indexOf(
      'stream.completed.listen((event) {',
    );
    final positionListenerStart = playerController.indexOf(
      'stream.position.listen((event) {',
    );
    expect(completedListenerStart, isNonNegative);
    expect(positionListenerStart, greaterThan(completedListenerStart));

    final completedListener = playerController.substring(
      completedListenerStart,
      positionListenerStart,
    );
    expect(completedListener, contains('if (!_isNearPlaybackEnd) {'));
    expect(completedListener, contains('refreshPlayer();'));
    expect(
      completedListener.indexOf('if (!_isNearPlaybackEnd) {'),
      lessThan(completedListener.indexOf('playerStatus.value = PlayerStatus.completed')),
    );
  });

  test('网络重试不会被瞬时0秒进度覆盖已播放位置', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(
      playerController,
      contains('Duration _lastValidPosition = Duration.zero;'),
    );
    expect(playerController, contains('Duration get _refreshStartPosition'));
    expect(playerController, contains('copyWith(start: _refreshStartPosition)'));
    expect(playerController, contains('if (event > Duration.zero) {'));
    expect(playerController, contains('_lastValidPosition = event;'));
  });

  test('锁屏完成时瞬时0秒仍按最后有效进度自动连播并记录完成', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final makeHeartBeatStart = playerController.indexOf(
      'Future<void>? makeHeartBeat(',
    );
    final setPlayRepeatStart = playerController.indexOf(
      'void setPlayRepeat(PlayRepeat type)',
    );
    expect(makeHeartBeatStart, isNonNegative);
    expect(setPlayRepeatStart, greaterThan(makeHeartBeatStart));

    final makeHeartBeat = playerController.substring(
      makeHeartBeatStart,
      setPlayRepeatStart,
    );
    expect(
      makeHeartBeat,
      contains('(type != HeartBeatType.completed && progress == 0)'),
    );
    expect(makeHeartBeat, contains('if (_isNearPlaybackEnd) {'));
    expect(makeHeartBeat, contains('progress = -1;'));
  });

  test('自动连播新源初始化后优先走页面回调，避免稍后再看丢失监听', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final initStart = playerController.indexOf(
      'Future<void> _initializePlayer() async {',
    );
    final listenersStart = playerController.indexOf(
      'List<StreamSubscription>? _subscriptions;',
    );
    expect(initStart, isNonNegative);
    expect(listenersStart, greaterThan(initStart));

    final initializePlayer = playerController.substring(
      initStart,
      listenersStart,
    );
    expect(initializePlayer, contains('await (playIfExists() ?? play());'));
  });

  test('锁屏后台生命周期暂停必须走播放器控制器保持媒体状态同步', () {
    final playerView = File('lib/plugin/pl_player/view/view.dart')
        .readAsStringSync();

    final lifecycleStart = playerView.indexOf(
      'void didChangeAppLifecycleState(AppLifecycleState state) {',
    );
    final brightnessStart = playerView.indexOf(
      'Future<void> setBrightness(double value) async {',
    );
    expect(lifecycleStart, isNonNegative);
    expect(brightnessStart, greaterThan(lifecycleStart));

    final lifecycle = playerView.substring(lifecycleStart, brightnessStart);
    expect(lifecycle, contains('plPlayerController.pause('));
    expect(lifecycle, contains('plPlayerController.play('));
    expect(lifecycle, isNot(contains('player.pause()')));
    expect(lifecycle, isNot(contains('player?.play()')));
  });

  test('允许后台播放时离开视频页不能暂停播放器，否则锁屏连播会中断', () {
    final videoPage = File('lib/pages/video/view.dart').readAsStringSync();

    final didPushNext = functionBody(videoPage, 'void didPushNext()');
    expect(didPushNext, contains('if (!Pref.continuePlayInBackground) {'));
    expect(didPushNext, contains('plPlayerController!.pause();'));
    expect(didPushNext, contains('removePositionListener(positionListener)'));
    expect(
      didPushNext,
      contains('if (!Pref.continuePlayInBackground || !isPlaying) {'),
    );
    expect(
      didPushNext.indexOf('plPlayerController!.pause();'),
      greaterThan(didPushNext.indexOf('if (!Pref.continuePlayInBackground) {')),
    );
  });

  test('后台连播切到下一条后不能一直停在封面不可见状态', () {
    final videoController = File(
      'lib/pages/video/controller.dart',
    ).readAsStringSync();

    final playerInit = functionBody(
      videoController,
      'Future<void> playerInit({',
    );
    expect(playerInit, contains('videoState.value = true;'));
    expect(
      playerInit.indexOf('videoState.value = true;'),
      lessThan(playerInit.indexOf('await plPlayerController.setDataSource(')),
    );
  });

  test('未知音频焦点事件不能中断后台播放，避免锁屏后停在暂停状态', () {
    final audioSession = File(
      'lib/services/audio_session.dart',
    ).readAsStringSync();

    final initSession = functionBody(audioSession, 'Future<void> initSession()');
    final unknownBegin = initSession.substring(
      initSession.indexOf('case AudioInterruptionType.unknown:'),
      initSession.indexOf('} else {'),
    );
    expect(unknownBegin, isNot(contains('pauseIfExists')));
    expect(unknownBegin, isNot(contains('_playInterrupted = true')));
  });

  test('自动连播换集暂停不向锁屏媒体服务发布用户暂停状态', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final pauseStart = playerController.indexOf(
      'Future<void> pause({bool notify = true, bool isInterrupt = false}) async {',
    );
    final nextMemberStart = playerController.indexOf(
      'bool tripling = false;',
    );
    expect(pauseStart, isNonNegative);
    expect(nextMemberStart, greaterThan(pauseStart));

    final pauseMethod = playerController.substring(pauseStart, nextMemberStart);
    expect(pauseMethod, contains('if (notify) {'));
    expect(pauseMethod, contains('playerStatus.value = PlayerStatus.paused;'));
    expect(
      pauseMethod.indexOf('playerStatus.value = PlayerStatus.paused;'),
      greaterThan(pauseMethod.indexOf('if (notify) {')),
    );
  });

  test('稍后再看跨视频连播按bvid或aid定位当前条目，不再误用当前分P cid', () {
    final ugcIntroController = File(
      'lib/pages/video/introduction/ugc/controller.dart',
    ).readAsStringSync();

    expect(
      ugcIntroController,
      contains('int _findCurrentPlayAllIndex(List<BaseEpisodeItem> episodes) {'),
    );
    expect(
      ugcIntroController,
      contains("(e.bvid?.isNotEmpty == true && e.bvid == bvid) ||"),
    );
    expect(
      ugcIntroController,
      contains('(e.aid != null && e.aid == videoDetailCtr.aid)'),
    );
    expect(
      ugcIntroController,
      contains('final int currentIndex = videoDetailCtr.isPlayAll && !isPart'),
    );
    expect(
      ugcIntroController,
      isNot(contains(
        "episodes.indexWhere(\n        (e) =>\n            e.cid ==\n            (skipPart",
      )),
    );
  });

  test('稍后再看播放完成后按默认开启设置静默移除当前视频且不阻塞下一条', () {
    final storageKey = File('lib/utils/storage_key.dart').readAsStringSync();
    final storagePref = File('lib/utils/storage_pref.dart').readAsStringSync();
    final playSettings = File(
      'lib/pages/setting/models/play_settings.dart',
    ).readAsStringSync();
    final videoPage = File('lib/pages/video/view.dart').readAsStringSync();

    expect(storageKey, contains("autoRemovePlayedWatchLater"));
    expect(
      storagePref,
      contains(
        '_setting.get(SettingBoxKey.autoRemovePlayedWatchLater, defaultValue: true)',
      ),
    );

    final settingIndex = playSettings.indexOf("title: '自动删除已播放视频'");
    final repeatIndex = playSettings.indexOf("title: '播放顺序'");
    expect(settingIndex, isNonNegative);
    expect(repeatIndex, greaterThan(settingIndex));
    final settingBlock = playSettings.substring(settingIndex, repeatIndex);
    expect(settingBlock, contains('setKey: SettingBoxKey.autoRemovePlayedWatchLater'));
    expect(settingBlock, contains('defaultVal: true'));

    expect(videoPage, contains("import 'package:PiliPlus/http/user.dart';"));
    expect(videoPage, contains("import 'package:PiliPlus/models/common/video/source_type.dart';"));
    expect(videoPage, contains('void _autoRemovePlayedWatchLater(int aid)'));
    expect(videoPage, contains('if (!Pref.autoRemovePlayedWatchLater) return;'));
    expect(videoPage, contains('if (videoDetailController.sourceType != SourceType.watchLater)'));
    expect(videoPage, contains('UserHttp.toViewDel(aids: aid.toString()).then((res) {'));
    expect(videoPage, contains('videoDetailController.mediaList.removeWhere((item) => item.aid == aid);'));

    final completedStart = videoPage.indexOf('if (status.isCompleted) {');
    final handlePlayStart = videoPage.indexOf('// 继续播放或重新播放');
    expect(completedStart, isNonNegative);
    expect(handlePlayStart, greaterThan(completedStart));
    final completedBlock = videoPage.substring(completedStart, handlePlayStart);
    expect(completedBlock, contains('final completedAid = videoDetailController.aid;'));
    expect(
      completedBlock,
      contains('exitFlag = !await introController.nextPlay();'),
    );
    expect(completedBlock, contains('_autoRemovePlayedWatchLater(completedAid);'));
    expect(
      completedBlock.indexOf('exitFlag = !await introController.nextPlay();'),
      lessThan(completedBlock.indexOf('_autoRemovePlayedWatchLater(completedAid);')),
    );
  });

  test('自动连播换源必须等待下一条初始化完成，避免旧源0秒重试串线', () {
    final commonIntroController = File(
      'lib/pages/common/common_intro_controller.dart',
    ).readAsStringSync();
    final ugcIntroController = File(
      'lib/pages/video/introduction/ugc/controller.dart',
    ).readAsStringSync();
    final pgcIntroController = File(
      'lib/pages/video/introduction/pgc/controller.dart',
    ).readAsStringSync();
    final localIntroController = File(
      'lib/pages/video/introduction/local/controller.dart',
    ).readAsStringSync();

    expect(commonIntroController, contains('Future<bool> nextPlay();'));
    expect(commonIntroController, contains('Future<bool> prevPlay();'));
    expect(commonIntroController, contains('Future<bool>? _playTransition;'));
    expect(commonIntroController, contains('Future<bool> runPlayTransition('));
    expect(ugcIntroController, contains('Future<bool> nextPlay('));
    expect(ugcIntroController, contains('runPlayTransition('));
    expect(ugcIntroController, contains('Future<bool> _changeEpisode('));
    final ugcChangeEpisode = functionBody(
      ugcIntroController,
      'Future<bool> _changeEpisode(',
    );
    expect(ugcChangeEpisode, contains('final oldAid = videoDetailCtr.aid;'));
    expect(ugcChangeEpisode, contains('final oldBvid = videoDetailCtr.bvid;'));
    expect(ugcChangeEpisode, contains('final oldCid = videoDetailCtr.cid.value;'));
    expect(ugcChangeEpisode, contains('final oldProgress ='));
    expect(ugcChangeEpisode, contains('positionSeconds.value;'));
    expect(
      ugcChangeEpisode,
      contains('plPlayerController.makeHeartBeat('),
    );
    expect(ugcChangeEpisode, contains('type: HeartBeatType.completed'));
    expect(ugcChangeEpisode, contains('isManual: true'));
    expect(ugcChangeEpisode, contains('aid: oldAid'));
    expect(ugcChangeEpisode, contains('bvid: oldBvid'));
    expect(
      ugcChangeEpisode,
      contains('cid: oldCid'),
    );
    expect(
      functionBody(ugcIntroController, 'Future<bool> _nextPlay('),
      contains('await _changeEpisode(episodes[nextIndex])'),
    );
    expect(
      functionBody(ugcIntroController, 'Future<bool> _nextPlay('),
      isNot(contains('return nextPlay(true);')),
    );
    expect(
      functionBody(ugcIntroController, 'Future<bool> _nextPlay('),
      isNot(contains('return playRelated();')),
    );
    expect(
      functionBody(ugcIntroController, 'Future<bool> _prevPlay('),
      contains('await _changeEpisode(episodes[prevIndex])'),
    );
    expect(
      functionBody(ugcIntroController, 'Future<bool> _prevPlay('),
      isNot(contains('return prevPlay(true);')),
    );
    expect(pgcIntroController, contains('Future<bool> nextPlay()'));
    expect(pgcIntroController, contains('runPlayTransition('));
    expect(pgcIntroController, contains('Future<bool> _changeEpisode('));
    final pgcChangeEpisode = functionBody(
      pgcIntroController,
      'Future<bool> _changeEpisode(',
    );
    expect(pgcChangeEpisode, contains('final oldAid = videoDetailCtr.aid;'));
    expect(pgcChangeEpisode, contains('final oldBvid = videoDetailCtr.bvid;'));
    expect(pgcChangeEpisode, contains('final oldCid = videoDetailCtr.cid.value;'));
    expect(pgcChangeEpisode, contains('final oldProgress ='));
    expect(pgcChangeEpisode, contains('positionSeconds.value;'));
    expect(
      pgcChangeEpisode,
      contains('plPlayerController.makeHeartBeat('),
    );
    expect(pgcChangeEpisode, contains('type: HeartBeatType.completed'));
    expect(pgcChangeEpisode, contains('isManual: true'));
    expect(pgcChangeEpisode, contains('aid: oldAid'));
    expect(pgcChangeEpisode, contains('bvid: oldBvid'));
    expect(
      pgcChangeEpisode,
      contains('cid: oldCid'),
    );
    expect(
      functionBody(pgcIntroController, 'Future<bool> _nextPlay('),
      contains('await _changeEpisode(episodes[nextIndex])'),
    );
    expect(
      functionBody(pgcIntroController, 'Future<bool> _prevPlay('),
      contains('await _changeEpisode(episodes[prevIndex])'),
    );
    expect(localIntroController, contains('runPlayTransition('));
    expect(localIntroController, contains('Future<bool> _playIndex('));
    expect(
      functionBody(localIntroController, 'Future<bool> _nextPlay('),
      contains('return _playIndex(next);'),
    );
    expect(
      functionBody(localIntroController, 'Future<bool> _nextPlay('),
      contains('return _playIndex(0);'),
    );
    expect(
      functionBody(localIntroController, 'Future<bool> _nextPlay('),
      isNot(contains('return playIndex(next);')),
    );
    expect(
      functionBody(localIntroController, 'Future<bool> _nextPlay('),
      isNot(contains('return playIndex(0);')),
    );
    expect(
      functionBody(localIntroController, 'Future<bool> _prevPlay('),
      contains('return _playIndex(prev);'),
    );
    expect(
      functionBody(localIntroController, 'Future<bool> _prevPlay('),
      isNot(contains('return playIndex(prev);')),
    );
  });

  test('网络打开错误只在启动阶段重试，避免新视频已播放后被错误事件打断', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final errorListenerStart = playerController.indexOf(
      'stream.error.listen((String event) {',
    );
    final mediaNotificationStart = playerController.indexOf(
      '// 媒体通知监听',
    );
    expect(errorListenerStart, isNonNegative);
    expect(mediaNotificationStart, greaterThan(errorListenerStart));

    final errorListener = playerController.substring(
      errorListenerStart,
      mediaNotificationStart,
    );
    expect(playerController, contains('bool get _shouldRetryOpenError'));
    final retryGuard = playerController.substring(
      playerController.indexOf('bool get _shouldRetryOpenError'),
      playerController.indexOf('static PlPlayerController? get instance'),
    );
    expect(retryGuard, contains('isBuffering.value'));
    expect(retryGuard, contains('position == Duration.zero'));
    expect(retryGuard, contains('_lastValidPosition == Duration.zero'));
    expect(errorListener, contains('if (_shouldRetryOpenError) {'));
    expect(
      errorListener,
      isNot(contains('if (isBuffering.value) {')),
    );
  });

  test('底层playing=false不直接当成用户暂停，断流恢复统一交给watchdog', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final playingListenerStart = playerController.indexOf(
      'stream.playing.listen((event) {',
    );
    final completedListenerStart = playerController.indexOf(
      'stream.completed.listen((event) {',
    );
    expect(playingListenerStart, isNonNegative);
    expect(completedListenerStart, greaterThan(playingListenerStart));

    final playingListener = playerController.substring(
      playingListenerStart,
      completedListenerStart,
    );
    expect(playingListener, isNot(contains('PlayerStatus.paused')));
    expect(playingListener, isNot(contains('_stopBufferWatchdog();')));
    expect(
      playingListener,
      contains('WakelockPlus.toggle(enable: event || playerStatus.isPlaying)'),
    );
    expect(playingListener, contains('if (event && !suppressPausedStatus) {'));
  });

  test('延迟网络重试不会跨视频源打断下一条播放', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(playerController, contains('int _sourceGeneration = 0;'));
    expect(playerController, contains('bool _sourceRefreshEnabled = true;'));
    expect(playerController, contains('_sourceGeneration++;'));
    expect(playerController, contains('if (isInterrupt) {'));
    expect(
      playerController,
      contains('_invalidateSourceGeneration(enableRefresh: false);'),
    );
    expect(
      playerController,
      contains('Future<void>? refreshPlayer({int? sourceGeneration})'),
    );
    expect(playerController, contains('!_sourceRefreshEnabled'));
    expect(
      playerController,
      contains('sourceGeneration != _sourceGeneration'),
    );
    expect(
      playerController,
      contains('final sourceGeneration = _sourceGeneration;'),
    );
    expect(
      playerController,
      contains('refreshPlayer(sourceGeneration: sourceGeneration)'),
    );
  });

  test('播放计时仍推进时也会检查缓冲是否停滞', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(playerController, contains('Timer? _bufferWatchdogTimer;'));
    expect(playerController, contains('void _startBufferWatchdog()'));
    expect(playerController, contains('const Duration(seconds: 2)'));
    expect(playerController, contains('void _checkBufferWatchdog()'));
    expect(
      playerController,
      contains('final positionAdvanced = position > _lastWatchdogPosition;'),
    );
    expect(
      playerController,
      contains('final bufferStalled = buffered.value <= _lastWatchdogBuffered;'),
    );
    expect(
      playerController,
      contains('final playbackOutrunsBuffer ='),
    );
    expect(playerController, contains('int _bufferWatchdogStallCount = 0;'));
    expect(playerController, contains('_bufferWatchdogStallCount++;'));
    expect(playerController, contains('if (_bufferWatchdogStallCount >= 3)'));
    expect(playerController, contains('final refresh = refreshPlayer();'));
    expect(playerController, contains('refresh.whenComplete('));
    expect(playerController, contains('_startBufferWatchdog();'));
    expect(playerController, contains('_stopBufferWatchdog();'));
  });

  test('锁屏恢复后卡在0秒也会触发当前视频重试', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(playerController, contains('final waitingForStartup ='));
    expect(playerController, contains('position == Duration.zero'));
    expect(playerController, contains('buffered.value == Duration.zero'));
    expect(playerController, contains('final shouldRefresh ='));
    expect(playerController, contains('waitingForStartup || playbackOutrunsBuffer'));
  });

  test('蓝牙补偿只注入mpv初始化参数，不参与页面和进度状态', () {
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    final initPlayerStart = playerController.indexOf(
      'Future<Player> _initPlayer() async {',
    );
    final createVideoControllerStart = playerController.indexOf(
      'Future<void> _createVideoController(',
    );
    expect(initPlayerStart, isNonNegative);
    expect(createVideoControllerStart, greaterThan(initPlayerStart));

    final initPlayer = playerController.substring(
      initPlayerStart,
      createVideoControllerStart,
    );
    expect(initPlayer, contains('BluetoothAudioDelay.queryOptionValue('));
    expect(initPlayer, contains("opt['video-delay'] = bluetoothAudioDelay;"));
    expect(initPlayer, contains('compensationMs: Pref.bluetoothAudioDelayMsOrNull,'));

    final completedListenerStart = playerController.indexOf(
      'stream.completed.listen((event) {',
    );
    final positionListenerStart = playerController.indexOf(
      'stream.position.listen((event) {',
    );
    final durationListenerStart = playerController.indexOf(
      'stream.duration.listen((Duration event) {',
    );
    expect(completedListenerStart, isNonNegative);
    expect(positionListenerStart, greaterThan(completedListenerStart));
    expect(durationListenerStart, greaterThan(positionListenerStart));

    final completedListener = playerController.substring(
      completedListenerStart,
      positionListenerStart,
    );
    final positionListener = playerController.substring(
      positionListenerStart,
      durationListenerStart,
    );
    expect(completedListener, isNot(contains('BluetoothAudioDelay')));
    expect(completedListener, isNot(contains('audio-delay')));
    expect(completedListener, isNot(contains('video-delay')));
    expect(positionListener, isNot(contains('BluetoothAudioDelay')));
    expect(positionListener, isNot(contains('audio-delay')));
    expect(positionListener, isNot(contains('video-delay')));
  });

  test('安卓播放设置支持调节倾斜角度切换视频方向', () {
    final playSettings = File(
      'lib/pages/setting/models/play_settings.dart',
    ).readAsStringSync();
    final playerController = File(
      'lib/plugin/pl_player/controller.dart',
    ).readAsStringSync();

    expect(playSettings, contains("title: '倾斜角度阈值'"));
    expect(playSettings, contains('value: Pref.angleDegrees.toDouble()'));
    expect(
      playSettings,
      contains('GStorage.setting.put(SettingBoxKey.angleDegrees, res.toInt())'),
    );
    expect(
      playerController,
      contains('angleDegrees: Platform.isAndroid ? Pref.angleDegrees : null'),
    );
  });

  test('蓝牙音频延迟优化默认启用并延后视频', () {
    expect(Pref.bluetoothAudioDelay, isTrue);
    expect(Pref.bluetoothAudioDelayMs, 320);
    expect(Pref.bluetoothAudioDelayMsOrNull, isNull);
    expect(
      BluetoothAudioDelay.optionValue(
        audioOutputType: BluetoothAudioDelayOutputType.a2dp,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMsOrNull,
      ),
      '0.300',
    );
    expect(
      BluetoothAudioDelay.optionValue(
        audioOutputType: BluetoothAudioDelayOutputType.none,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMsOrNull,
      ),
      isNull,
    );
  });

  test('蓝牙自动补偿按输出路由选择默认值', () {
    expect(
      BluetoothAudioDelay.automaticCompensationMs(
        BluetoothAudioDelayOutputType.a2dp,
      ),
      300,
    );
    expect(
      BluetoothAudioDelay.automaticCompensationMs(
        BluetoothAudioDelayOutputType.ble,
      ),
      180,
    );
    expect(
      BluetoothAudioDelay.automaticCompensationMs(
        BluetoothAudioDelayOutputType.sco,
      ),
      120,
    );
  });

  test('用户手动补偿值优先于蓝牙自动补偿', () async {
    await GStorage.setting.put(SettingBoxKey.bluetoothAudioDelayMs, 260);

    expect(Pref.bluetoothAudioDelayMsOrNull, 260);
    expect(
      BluetoothAudioDelay.optionValue(
        audioOutputType: BluetoothAudioDelayOutputType.a2dp,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMsOrNull,
      ),
      '0.260',
    );

    await GStorage.setting.delete(SettingBoxKey.bluetoothAudioDelayMs);
  });

  test('蓝牙音频补偿量限制在0到400ms', () {
    expect(
      BluetoothAudioDelay.optionValue(
        audioOutputType: BluetoothAudioDelayOutputType.a2dp,
        enabled: true,
        compensationMs: -20,
      ),
      isNull,
    );
    expect(
      BluetoothAudioDelay.optionValue(
        audioOutputType: BluetoothAudioDelayOutputType.a2dp,
        enabled: true,
        compensationMs: 999,
      ),
      '0.400',
    );
  });

  test('音视频设置页提供蓝牙延迟优化入口', () {
    final switchSetting = videoSettings.whereType<SwitchModel>().singleWhere(
      (item) => item.setKey == SettingBoxKey.bluetoothAudioDelay,
    );
    final delaySetting = videoSettings.whereType<NormalModel>().singleWhere(
      (item) => item.title == '蓝牙音频补偿量',
    );

    expect(switchSetting.defaultVal, isTrue);
    expect(delaySetting.effectiveSubtitle, contains('自动'));
    expect(delaySetting.effectiveSubtitle, contains('A2DP 300ms'));
    expect(delaySetting.effectiveSubtitle, contains('BLE 180ms'));
  }, skip: !Platform.isAndroid);
}
