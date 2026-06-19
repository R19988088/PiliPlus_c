import 'dart:math' as math;

import 'package:flutter/material.dart';

Color buildGlassNavTint({
  required Color primary,
  required bool navUsesLightDefinition,
  required double saturationMin,
  required double saturationMax,
  required double lightnessLight,
  required double lightnessDark,
  required int brightness,
  required int opacity,
}) {
  final baseColor = HSLColor.fromColor(primary)
      .withSaturation(
        (navUsesLightDefinition ? saturationMin : saturationMax)
            .clamp(0.0, 1.0)
            .toDouble(),
      )
      .withLightness(
        (navUsesLightDefinition ? lightnessDark : lightnessLight)
            .clamp(0.0, 1.0)
            .toDouble(),
      )
      .toColor();

  return applyGlassNavBrightnessCurve(
    baseColor,
    brightness,
  ).withValues(alpha: opacity.clamp(0, 100).toDouble() / 100);
}

Color applyGlassNavBrightnessCurve(Color color, int brightness) {
  final normalized = brightness.clamp(0, 100).toDouble() / 100;
  final gamma = math.pow(2, 1 - normalized * 2).toDouble();
  final argb = color.toARGB32();

  int curve(int component) {
    final adjusted = math.pow(component / 255, gamma) * 255;
    return adjusted.round().clamp(0, 255).toInt();
  }

  return Color.fromARGB(
    (argb >> 24) & 0xff,
    curve((argb >> 16) & 0xff),
    curve((argb >> 8) & 0xff),
    curve(argb & 0xff),
  );
}
