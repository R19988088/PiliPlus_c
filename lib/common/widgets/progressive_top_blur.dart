import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withValues(alpha: 0.92),
              colorScheme.surface.withValues(alpha: 0.36),
              colorScheme.surface.withValues(alpha: 0),
            ],
            stops: const [0, 0.56, 1],
          ),
        ),
        child: SizedBox(
          height: extent,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: extent * 0.58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.28),
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
  });

  final Widget body;
  final Widget topBar;
  final double blurExtent;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ProgressiveTopBlur(
            extent: topInset + blurExtent,
          ),
        ),
        Positioned.fill(child: body),
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
