import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

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
    final fillColor = (backgroundColor ?? colorScheme.surfaceContainer)
        .withValues(alpha: isDark ? 0.46 : 0.58);

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
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: fillColor,
              shape: shape,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.18 : 0.52),
                    Colors.white.withValues(alpha: isDark ? 0.05 : 0.16),
                    colorScheme.primary.withValues(alpha: isDark ? 0.07 : 0.05),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
                shape: shape,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
