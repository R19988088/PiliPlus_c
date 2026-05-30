import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('我的页主题按钮只在浅色和深色之间切换', () {
    final mineController = File(
      'lib/pages/mine/controller.dart',
    ).readAsStringSync();

    expect(
      mineController,
      contains(
        'themeType.value == ThemeType.light ? ThemeType.dark : ThemeType.light',
      ),
    );
    expect(mineController, isNot(contains('ThemeType.values[(themeType.value.index + 1)')));
  });

  test('设置页隐藏主题模式选择入口但保留实现函数', () {
    final styleSettings = File(
      'lib/pages/setting/models/style_settings.dart',
    ).readAsStringSync();
    final visibleSettings = styleSettings.split(
      'Future<void> _showThemeTypeDialog',
    ).first;

    expect(styleSettings, contains('Future<void> _showThemeTypeDialog'));
    expect(visibleSettings, isNot(contains("title: '主题模式'")));
    expect(visibleSettings, isNot(contains('onTap: _showThemeTypeDialog')));
  });
}
