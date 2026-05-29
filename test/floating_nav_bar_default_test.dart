import 'dart:io';

import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/style_settings.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
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

  test('悬浮底栏外观设置默认启用', () {
    final setting = styleSettings.whereType<SwitchModel>().singleWhere(
      (item) => item.setKey == SettingBoxKey.floatingNavBar,
    );

    expect(setting.defaultVal, isTrue);
  });

  test('外观设置不再允许隐藏首页底栏', () {
    final bottomBarHideSettings = styleSettings.whereType<SwitchModel>().where(
      (item) => item.setKey == SettingBoxKey.hideBottomBar,
    );

    expect(bottomBarHideSettings, isEmpty);
  });
}
