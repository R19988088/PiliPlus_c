import 'package:flutter/material.dart';

class VipVideoBadge extends StatelessWidget {
  const VipVideoBadge({
    super.key,
    this.top,
    this.right,
  });

  final double? top;
  final double? right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final color = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.8),
      theme.primary,
    );

    return Positioned(
      top: top,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.primary),
        ),
        child: const Text(
          '会员视频',
          textScaler: TextScaler.linear(1),
          style: TextStyle(
            height: 1,
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          strutStyle: StrutStyle(
            leading: 0,
            height: 1,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
