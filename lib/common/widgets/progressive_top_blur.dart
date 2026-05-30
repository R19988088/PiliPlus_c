import 'package:flutter/material.dart';
import 'package:progressive_blur/progressive_blur.dart';

class ProgressiveTopBlur extends StatelessWidget {
  const ProgressiveTopBlur({
    super.key,
    required this.child,
    this.sigma = 20,
  });

  final Widget child;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ProgressiveBlurWidget(
            sigma: sigma,
            linearGradientBlur: const LinearGradientBlur(
              values: [1, 0],
              stops: [0, 1],
              start: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            tintColor: colorScheme.surface.withValues(alpha: 0.10),
            child: const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}
