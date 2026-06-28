import 'dart:ui';

import 'package:flutter/material.dart';

class ProgressiveTopBlur extends StatelessWidget {
  const ProgressiveTopBlur({
    super.key,
    this.sigma = 20,
  });

  final double sigma;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.62, 1],
                ).createShader(bounds);
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.32),
                    colorScheme.surface.withValues(alpha: 0.12),
                    colorScheme.surface.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.54, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressiveTopBlurOverlay extends StatelessWidget {
  const ProgressiveTopBlurOverlay({
    super.key,
    required this.body,
    required this.topBar,
    this.topBarExtent = 0,
    this.blurExtent = 96,
  });

  final Widget body;
  final Widget topBar;
  final double topBarExtent;
  final double blurExtent;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(
          child: topBarExtent == 0
              ? body
              : Padding(
                  padding: EdgeInsets.only(top: topInset + topBarExtent),
                  child: body,
                ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + blurExtent,
          child: const ProgressiveTopBlur(),
        ),
        Positioned(
          top: topInset,
          left: 0,
          right: 0,
          child: topBar,
        ),
      ],
    );
  }
}
