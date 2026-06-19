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

double glassNavLightIntensityForBrightness(
  int brightness, {
  double neutral = 0.6,
}) => _brightnessCurve(
  brightness,
  dark: 0.16,
  neutral: neutral,
  light: 1.35,
);

double glassNavAmbientStrengthForBrightness(
  int brightness, {
  double neutral = 1.0,
}) => _brightnessCurve(
  brightness,
  dark: 0.26,
  neutral: neutral,
  light: 1.75,
);

double _brightnessCurve(
  int brightness, {
  required double dark,
  required double neutral,
  required double light,
}) {
  final clamped = brightness.clamp(0, 100);
  if (clamped == 50) return neutral;

  if (clamped < 50) {
    final t = clamped / 50;
    final eased = math.pow(t, 1.4).toDouble();
    return dark + (neutral - dark) * eased;
  }

  final t = (clamped - 50) / 50;
  final eased = 1 - math.pow(1 - t, 1.4).toDouble();
  return neutral + (light - neutral) * eased;
}
