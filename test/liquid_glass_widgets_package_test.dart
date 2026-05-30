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
    expect(navigationBar, contains('label: null'));
    expect(navigationBar, contains("const _kGlassNavBarVersion = '液态玻璃0.5'"));
    expect(navigationBar, contains('const _kBottomBarGlassDefaults = LiquidGlassSettings'));
    expect(navigationBar, contains('quality: GlassQuality.standard'));
    expect(navigationBar, contains('glassSettings: _kBottomBarGlassDefaults.copyWith'));
    expect(navigationBar, contains('HSLColor.fromColor(colorScheme.primary)'));
    expect(navigationBar, contains('Pref.glassNavSaturationMin'));
    expect(navigationBar, contains('Pref.glassNavSaturationMax'));
    expect(navigationBar, contains('Pref.glassNavLightnessLight'));
    expect(navigationBar, contains('Pref.glassNavLightnessDark'));
    expect(navigationBar, contains('final iconColor = isLight ? Colors.white : Colors.black'));
    expect(navigationBar, contains('glassColor: navTint.withValues(alpha: 0.90)'));
    expect(navigationBar, contains('boxShadow:'));
    expect(navigationBar, contains('interactionGlowColor: colorScheme.primary'));
    expect(navigationBar, isNot(contains('indicatorSettings:')));
    expect(navigationBar, isNot(contains('magnification:')));
    expect(navigationBar, isNot(contains('innerBlur:')));
    expect(navigationBar, isNot(contains('indicatorExpansion:')));
    expect(navigationBar, isNot(contains('pressScale:')));

    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('LiquidGlassWidgets.initialize()'));
    expect(main, contains('LiquidGlassWidgets.wrap'));
    expect(main, contains('GlassThemeData.simple'));
    expect(main, contains('GlassBackdropScope'));
    expect(main, contains('respectSystemAccessibility: false'));
    expect(main, contains('quality: GlassQuality.premium'));
    expect(main, isNot(contains('adaptiveQuality: true')));
    expect(main, isNot(contains('quality: GlassQuality.standard')));

    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      matches(
        RegExp(
          r'android:name="io\.flutter\.embedding\.android\.EnableImpeller"[\s\S]*?android:value="true"',
        ),
      ),
    );
  });
}
