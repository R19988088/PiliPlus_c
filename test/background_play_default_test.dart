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

  test('蓝牙音频延迟优化默认启用并提前音频', () {
    expect(Pref.bluetoothAudioDelay, isTrue);
    expect(Pref.bluetoothAudioDelayMs, 180);
    expect(
      BluetoothAudioDelay.optionValue(
        isBluetoothAudioOutput: true,
        enabled: true,
        compensationMs: Pref.bluetoothAudioDelayMs,
      ),
      '-0.180',
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
    expect(delaySetting.effectiveSubtitle, contains('180ms'));
  }, skip: !Platform.isAndroid);
}
