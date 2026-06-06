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
      completedListener,
      contains('videoPlayerServiceHandler?.onStatusChange('),
    );
    expect(
      completedListener.indexOf('playerStatus.value = PlayerStatus.completed'),
      lessThan(
        completedListener.indexOf('videoPlayerServiceHandler?.onStatusChange('),
      ),
    );
    expect(
      completedListener.indexOf('videoPlayerServiceHandler?.onStatusChange('),
      lessThan(
        completedListener.indexOf('for (final element in _statusListeners)'),
      ),
    );
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

  test('蓝牙音频延迟优化默认启用并提前音频', () {
    expect(Pref.bluetoothAudioDelay, isTrue);
    expect(Pref.bluetoothAudioDelayMs, 320);
    expect(
      BluetoothAudioDelay.optionValue(
        isBluetoothAudioOutput: true,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMs,
      ),
      '-0.320',
    );
    expect(
      BluetoothAudioDelay.optionValue(
        isBluetoothAudioOutput: false,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMs,
      ),
      isNull,
    );
  });

  test('蓝牙音频提前量限制在0到400ms', () {
    expect(
      BluetoothAudioDelay.optionValue(
        isBluetoothAudioOutput: true,
        enabled: true,
        compensationMs: -20,
      ),
      isNull,
    );
    expect(
      BluetoothAudioDelay.optionValue(
        isBluetoothAudioOutput: true,
        enabled: true,
        compensationMs: 999,
      ),
      '-0.400',
    );
  });

  test('音视频设置页提供蓝牙延迟优化入口', () {
    final switchSetting = videoSettings.whereType<SwitchModel>().singleWhere(
      (item) => item.setKey == SettingBoxKey.bluetoothAudioDelay,
    );
    final delaySetting = videoSettings.whereType<NormalModel>().singleWhere(
      (item) => item.title == '蓝牙音频提前量',
    );

    expect(switchSetting.defaultVal, isTrue);
    expect(delaySetting.effectiveSubtitle, contains('320ms'));
  }, skip: !Platform.isAndroid);
}
