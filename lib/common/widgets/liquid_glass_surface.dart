import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.shape,
    required this.child,
    this.backgroundColor,
    this.blurSigma = 18.0,
  });

  final ShapeBorder shape;
  final Widget child;
  final Color? backgroundColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassColor = (backgroundColor ?? colorScheme.surfaceContainer)
        .withValues(alpha: isDark ? 0.20 : 0.18);
    final borderSide = BorderSide(
      color: colorScheme.outlineVariant.withValues(
        alpha: isDark ? 0.18 : 0.30,
      ),
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GlassContainer(
        shape: LiquidRoundedSuperellipse(
          borderRadius: _shapeRadius(shape),
          side: borderSide,
        ),
        settings: LiquidGlassSettings(
          glassColor: glassColor,
          blur: blurSigma,
          thickness: 28,
          chromaticAberration: 0.18,
          refractiveIndex: 1.16,
          saturation: 1.28,
          lightIntensity: isDark ? 0.36 : 0.48,
          ambientStrength: isDark ? 0.08 : 0.12,
        ),
        quality: GlassQuality.premium,
        useOwnLayer: true,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  double _shapeRadius(ShapeBorder shape) {
    if (shape is RoundedSuperellipseBorder) {
      final radius = shape.borderRadius.resolve(TextDirection.ltr).topLeft;
      return radius.x;
    }
    if (shape is RoundedRectangleBorder) {
      final radius = shape.borderRadius.resolve(TextDirection.ltr).topLeft;
      return radius.x;
    }
    return 32;
  }
}
