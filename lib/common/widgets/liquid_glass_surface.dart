import 'dart:ui' as ui show FragmentProgram, ImageFilter;

import 'package:flutter/material.dart';

const liquidGlassRefractionShaderAsset = 'shaders/liquid_glass_refraction.frag';

Future<ui.FragmentProgram>? _liquidGlassRefractionProgram;

Future<ui.FragmentProgram> _loadLiquidGlassRefractionProgram() =>
    _liquidGlassRefractionProgram ??=
        ui.FragmentProgram.fromAsset(liquidGlassRefractionShaderAsset);

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
        .withValues(alpha: isDark ? 0.40 : 0.44);

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
        child: FutureBuilder<ui.FragmentProgram>(
          future: _loadLiquidGlassRefractionProgram(),
          builder: (context, snapshot) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final filter = _createBackdropFilter(snapshot.data, size);

                return BackdropFilter(
                  filter: filter,
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
                            Colors.white.withValues(
                              alpha: isDark ? 0.16 : 0.34,
                            ),
                            Colors.white.withValues(
                              alpha: isDark ? 0.04 : 0.10,
                            ),
                            colorScheme.primary.withValues(
                              alpha: isDark ? 0.08 : 0.06,
                            ),
                          ],
                          stops: const [0.0, 0.46, 1.0],
                        ),
                        shape: shape,
                      ),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  ui.ImageFilter _createBackdropFilter(
    ui.FragmentProgram? refractionProgram,
    Size size,
  ) {
    final blurFilter = ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
    if (refractionProgram == null ||
        !ui.ImageFilter.isShaderFilterSupported ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.isEmpty) {
      return blurFilter;
    }

    final radius = size.height / 2;
    // ImageFilter.shader fills the first vec2 uniform with the input texture
    // size. The remaining float uniforms begin at index 2.
    final shader = refractionProgram.fragmentShader()
      ..setFloat(2, radius)
      ..setFloat(3, radius)
      ..setFloat(4, radius)
      ..setFloat(5, radius)
      ..setFloat(6, 24)
      ..setFloat(7, 24)
      ..setFloat(8, 0)
      ..setFloat(9, 0.45);

    return ui.ImageFilter.compose(
      outer: ui.ImageFilter.shader(shader),
      inner: blurFilter,
    );
  }
}
