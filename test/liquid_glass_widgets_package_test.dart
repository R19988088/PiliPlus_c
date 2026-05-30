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
    expect(navigationBar, contains("const _kGlassNavBarVersion = '导航条9.9'"));
    expect(navigationBar, contains('const _kBottomBarGlassDefaults = LiquidGlassSettings'));
    expect(navigationBar, contains('Pref.glassNavBlur.clamp(0, 100) / 10'));
    expect(navigationBar, contains('Pref.glassNavThickness.clamp(0, 100) * 0.6'));
    expect(navigationBar, contains('Pref.glassNavChromaticAberration.clamp(0, 200) / 100'));
    expect(navigationBar, contains('Pref.glassNavRefraction.clamp(0, 200) * 0.0118'));
    expect(navigationBar, isNot(contains('quality: GlassQuality.standard')));
    expect(navigationBar, contains('glassSettings: _kBottomBarGlassDefaults.copyWith'));
    expect(navigationBar, contains('HSLColor.fromColor(colorScheme.primary)'));
    expect(navigationBar, isNot(contains('Pref.glassNavSaturationMin')));
    expect(navigationBar, isNot(contains('Pref.glassNavSaturationMax')));
    expect(navigationBar, isNot(contains('Pref.glassNavLightnessLight')));
    expect(navigationBar, isNot(contains('Pref.glassNavLightnessDark')));
    expect(navigationBar, contains('final navUsesLightDefinition = Pref.inverseNavigationBar'));
    expect(navigationBar, contains('withSaturation(navUsesLightDefinition ? 0.12 : 0.18)'));
    expect(navigationBar, contains('withLightness(navUsesLightDefinition ? 1.0 : 0.20)'));
    expect(navigationBar, contains('withValues(alpha: Pref.glassNavOpacity.clamp(0, 100) / 100)'));
    expect(navigationBar, contains('final iconColor = navUsesLightDefinition ? Colors.black : Colors.white'));
    expect(navigationBar, contains('size: 26.4'));
    expect(navigationBar, contains('weight: 700'));
    expect(navigationBar, contains('glassColor: navTint'));
    expect(navigationBar, contains('thickness: glassThickness'));
    expect(navigationBar, contains('blur: glassBlur'));
    expect(navigationBar, contains('chromaticAberration: chromaticAberration'));
    expect(navigationBar, contains('refractiveIndex: refractiveIndex'));
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

    final pref = File('lib/utils/storage_pref.dart').readAsStringSync();
    expect(pref, contains('SettingBoxKey.glassNavOpacity, defaultValue: 10'));
    expect(
      pref,
      contains('SettingBoxKey.glassNavChromaticAberration,\n    defaultValue: 190'),
    );
    expect(pref, contains('SettingBoxKey.glassNavBlur, defaultValue: 50'));
    expect(pref, contains('SettingBoxKey.glassNavThickness, defaultValue: 50'));

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
