import 'dart:io';

import 'package:PiliPlus/common/widgets/liquid_glass_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('液态玻璃折射 shader 使用 AndroidLiquidGlass 算法移植', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains(liquidGlassRefractionShaderAsset));

    final shader = File(liquidGlassRefractionShaderAsset).readAsStringSync();
    expect(shader, contains('Copyright 2025 Kyant'));
    expect(shader, contains('Apache License, Version 2.0'));
    expect(shader, contains('sdRoundedRect'));
    expect(shader, contains('u_refraction_height'));
    expect(shader, contains('u_chromatic_aberration'));

    final notice = File('shaders/NOTICE.md').readAsStringSync();
    expect(notice, contains('Kyant0/AndroidLiquidGlass'));
    expect(notice, contains('Apache License, Version 2.0'));
  });
}
