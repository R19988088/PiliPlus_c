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

  test('外观设置不再展示固定策略选项', () {
    final hiddenKeys = {
      SettingBoxKey.enableMYBar,
      SettingBoxKey.floatingNavBar,
      SettingBoxKey.hideTopBar,
      SettingBoxKey.barHideType,
      SettingBoxKey.isPureBlackTheme,
      SettingBoxKey.hideBottomBar,
    };

    final switchKeys = styleSettings.whereType<SwitchModel>().map(
      (item) => item.setKey,
    );
    final titles = styleSettings.map((item) => item.effectiveTitle);

    for (final key in hiddenKeys) {
      expect(switchKeys, isNot(contains(key)));
    }
    expect(titles, isNot(contains('顶栏收起类型')));
    expect(titles, contains('反色导航栏'));
    expect(titles, containsAll(['导航条效果', '透明度', '折射强度', '色散', '模糊强度', '厚度']));
  });

  test('主页面不再包装底栏滑动隐藏动画', () {
    final mainView = File('lib/pages/main/view.dart').readAsStringSync();

    expect(mainView, isNot(contains('AnimatedSlide')));
    expect(mainView, isNot(contains('FractionalTranslation')));
  });
}
