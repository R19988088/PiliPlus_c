import 'dart:ui';

import 'package:flutter/material.dart';

class ProgressiveTopBlur extends StatelessWidget {
  const ProgressiveTopBlur({
    super.key,
    required this.extent,
    this.sigma = 24,
  });

  final double extent;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.44),
                  colorScheme.surface.withValues(alpha: 0.18),
                  colorScheme.surface.withValues(alpha: 0),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
            child: SizedBox(
              height: extent,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: extent * 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    this.blurExtent = 96,
    this.topBarHeight = 0,
    this.foreground,
  });

  final Widget body;
  final Widget topBar;
  final double blurExtent;
  final double topBarHeight;
  final Widget? foreground;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(child: body),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + blurExtent,
          child: ProgressiveTopBlur(extent: topInset + blurExtent),
        ),
        Positioned(
          top: topInset,
          left: 0,
          right: 0,
          child: topBar,
        ),
        if (foreground case final foreground?)
          Positioned(
            top: topInset + topBarHeight,
            left: 0,
            right: 0,
            child: foreground,
          ),
      ],
    );
  }
}
