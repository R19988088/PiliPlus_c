import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

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
    return SoftEdgeBlur(
      edges: [
        EdgeBlur(
          type: EdgeType.topEdge,
          size: extent,
          sigma: sigma,
          tintColor: colorScheme.surface.withValues(alpha: 0.18),
          controlPoints: [
            ControlPoint(position: 0, type: ControlPointType.visible),
            ControlPoint(position: 0.58, type: ControlPointType.visible),
            ControlPoint(position: 1, type: ControlPointType.transparent),
          ],
        ),
      ],
      child: Stack(
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
                      colorScheme.surface.withValues(alpha: 0.16),
                      colorScheme.surface.withValues(alpha: 0.06),
                      colorScheme.surface.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
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
