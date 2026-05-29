import 'dart:io';

import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
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
}
