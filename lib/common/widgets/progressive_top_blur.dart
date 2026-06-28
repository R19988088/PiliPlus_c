import 'package:flutter/material.dart';

class ProgressiveTopBlur extends StatelessWidget {
  const ProgressiveTopBlur({
    super.key,
    required this.child,
    required this.extent,
    this.sigma = 24,
  });

  final Widget child;
  final double extent;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: extent,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.92),
                    colorScheme.surface.withValues(alpha: 0.56),
                    colorScheme.surface.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProgressiveTopBlurOverlay extends StatelessWidget {
  const ProgressiveTopBlurOverlay({
    super.key,
    required this.body,
    required this.topBar,
    this.blurExtent = 96,
  });

  final Widget body;
  final Widget topBar;
  final double blurExtent;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(
          child: ProgressiveTopBlur(
            extent: topInset + blurExtent,
            child: body,
          ),
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
