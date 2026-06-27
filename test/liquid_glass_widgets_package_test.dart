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
    expect(navigationBar, contains("const _kGlassNavBarVersion = '导航条10.0'"));
    expect(navigationBar, contains('const _kBottomBarGlassDefaults = LiquidGlassSettings'));
    expect(navigationBar, contains('Pref.glassNavBlur.clamp(0, 100) / 10'));
    expect(navigationBar, contains('Pref.glassNavThickness.clamp(0, 100).toDouble()'));
    expect(navigationBar, contains('Pref.glassNavChromaticAberration.clamp(0, 200) / 100'));
    expect(navigationBar, contains('Pref.glassNavRefraction.clamp(0, 100) * 0.0118'));
    expect(navigationBar, contains('buildGlassNavTint('));
    expect(navigationBar, isNot(contains('quality: GlassQuality.standard')));
    expect(navigationBar, contains('glassSettings: _kBottomBarGlassDefaults.copyWith'));
    expect(navigationBar, contains('Pref.glassNavSaturationMin'));
    expect(navigationBar, contains('Pref.glassNavSaturationMax'));
    expect(navigationBar, contains('Pref.glassNavLightnessLight'));
    expect(navigationBar, contains('Pref.glassNavLightnessDark'));
    expect(navigationBar, contains('brightness: Pref.glassNavBlend'));
    expect(navigationBar, contains('final navUsesLightDefinition = Pref.inverseNavigationBar'));
    expect(navigationBar, contains('final iconColor = navUsesLightDefinition ? Colors.black : Colors.white'));
    expect(navigationBar, contains('size: 26.4'));
    expect(navigationBar, contains('weight: 700'));
    expect(navigationBar, contains('glassColor: navTint'));
    expect(navigationBar, contains('lightIntensity: glassLightIntensity'));
    expect(navigationBar, contains('ambientStrength: glassAmbientStrength'));
    expect(navigationBar, contains('thickness: glassLensRadius'));
    expect(navigationBar, contains('blur: glassBlur'));
    expect(navigationBar, contains('chromaticAberration: chromaticAberration'));
    expect(navigationBar, contains('refractiveIndex: refractiveIndex'));
    expect(navigationBar, isNot(contains('blend: glassBlend')));
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
    expect(pref, contains('defaultValue: ThemeType.light.index'));
    expect(pref, contains('SettingBoxKey.glassNavOpacity, defaultValue: 10'));
    expect(
      pref,
      contains('SettingBoxKey.glassNavChromaticAberration,\n    defaultValue: 50'),
    );
    expect(pref, contains('SettingBoxKey.glassNavBlur, defaultValue: 10'));
    expect(pref, contains('SettingBoxKey.glassNavRefraction, defaultValue: 20'));
    expect(pref, contains('SettingBoxKey.glassNavThickness, defaultValue: 40'));
    expect(pref, contains('SettingBoxKey.glassNavBlend, defaultValue: 50'));

    final glassNavTint = File(
      'lib/common/widgets/glass_nav_tint.dart',
    ).readAsStringSync();
    expect(glassNavTint, contains('math.pow('));
    expect(glassNavTint, contains('buildGlassNavTint'));
    expect(glassNavTint, contains('double glassNavLightIntensityForBrightness'));
    expect(glassNavTint, contains('double glassNavAmbientStrengthForBrightness'));
    expect(glassNavTint, contains('if (clamped == 50) return neutral'));
    expect(glassNavTint, isNot(contains('Colors.black')));
    expect(glassNavTint, isNot(contains('Colors.white')));

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

  test('首页和动态顶部使用 Flutter 原生渐变模糊', () {
    final progressiveTopBlur = File(
      'lib/common/widgets/progressive_top_blur.dart',
    ).readAsStringSync();
    expect(progressiveTopBlur, contains("import 'dart:ui';"));
    expect(progressiveTopBlur, contains('BackdropFilter'));
    expect(progressiveTopBlur, contains('ImageFilter.blur'));
    expect(progressiveTopBlur, contains('ShaderMask'));
    expect(progressiveTopBlur, contains('BlendMode.dstIn'));
    expect(progressiveTopBlur, contains('class ProgressiveTopBlurOverlay'));
    expect(progressiveTopBlur, contains('Positioned.fill(child: body)'));
    expect(progressiveTopBlur, isNot(contains('ProgressiveBlurWidget')));
    expect(progressiveTopBlur, isNot(contains('LinearGradientBlur')));

    final home = File('lib/pages/home/view.dart').readAsStringSync();
    expect(home, contains('ProgressiveTopBlurOverlay'));
    expect(home, isNot(contains('return Column(\n      children: [\n        topBar,')));
    expect(
      home,
      isNot(
        contains('color: theme.colorScheme.surface,\n          child: tabBar'),
      ),
    );

    final dynamics = File('lib/pages/dynamics/view.dart').readAsStringSync();
    expect(dynamics, contains('ProgressiveTopBlurOverlay'));
    expect(dynamics, contains('Widget _buildTopBar('));
    expect(dynamics, isNot(contains('Expanded(child: onBuild(child))')));
    expect(dynamics, isNot(contains('extendBodyBehindAppBar: true')));
    expect(dynamics, isNot(contains('appBar: AppBar(')));
    expect(dynamics, isNot(contains('backgroundColor: Colors.transparent')));

    final dynamicsTab = File(
      'lib/pages/dynamics_tab/view.dart',
    ).readAsStringSync();
    expect(dynamicsTab, isNot(contains('_kDynamicsTopOverlayHeight')));
    expect(dynamicsTab, isNot(contains('top: 50')));
  });

  test('Android versionCode 不低于已发布构建号', () {
    final buildScript = File('lib/scripts/build.ps1').readAsStringSync();
    expect(buildScript, contains("if (\$Arg -eq 'android')"));
    expect(buildScript, contains('[Math]::Max($versionCode, 5130)'));
  });
}
