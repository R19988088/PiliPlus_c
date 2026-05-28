import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('液态玻璃导航栏直接使用 liquid_glass_widgets 包', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('liquid_glass_widgets: ^0.12.8'));
    expect(pubspec, isNot(contains('shaders/liquid_glass_refraction.frag')));

    final surface = File(
      'lib/common/widgets/liquid_glass_surface.dart',
    ).readAsStringSync();
    expect(surface, contains('package:liquid_glass_widgets'));
    expect(surface, contains('GlassContainer'));
    expect(surface, contains('LiquidRoundedSuperellipse'));
    expect(surface, isNot(contains('FragmentProgram.fromAsset')));

    final navigationBar = File(
      'lib/common/widgets/floating_navigation_bar.dart',
    ).readAsStringSync();
    expect(navigationBar, contains('GlassBottomBar'));
    expect(navigationBar, contains('GlassBottomBarTab'));
    expect(navigationBar, contains('MaskingQuality.high'));

    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('LiquidGlassWidgets.initialize()'));
    expect(main, contains('LiquidGlassWidgets.wrap'));
    expect(main, contains('GlassThemeData.simple'));
    expect(main, contains('GlassBackdropScope'));
  });
}
