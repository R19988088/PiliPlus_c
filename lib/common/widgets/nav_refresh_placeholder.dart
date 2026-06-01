import 'package:PiliPlus/common/style.dart';
import 'package:flutter/material.dart';

class NavRefreshPlaceholder extends StatelessWidget {
  const NavRefreshPlaceholder({
    super.key,
    required this.columns,
    required this.itemCount,
    this.padding = EdgeInsets.zero,
    this.aspectRatio = Style.aspectRatio,
    this.maxCrossAxisExtent,
    this.mainAxisExtent,
    this.crossAxisSpacing = Style.cardSpace,
    this.mainAxisSpacing = Style.cardSpace,
    this.borderRadius = Style.mdRadius,
  });

  final int columns;
  final int itemCount;
  final EdgeInsets padding;
  final double aspectRatio;
  final double? maxCrossAxisExtent;
  final double? mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - padding.left - padding.right;
        final resolvedColumns =
            maxCrossAxisExtent != null && maxCrossAxisExtent! > 0
            ? ((availableWidth + crossAxisSpacing) /
                      (maxCrossAxisExtent! + crossAxisSpacing))
                  .floor()
                  .clamp(1, itemCount)
            : columns;
        final rawItemWidth = resolvedColumns > 0
            ? (availableWidth - crossAxisSpacing * (resolvedColumns - 1)) /
                  resolvedColumns
            : availableWidth;
        final itemWidth = rawItemWidth > 0 ? rawItemWidth : 0.0;
        final itemHeight =
            mainAxisExtent ??
            (itemWidth > 0 ? itemWidth / aspectRatio : constraints.maxHeight);

        return Padding(
          padding: padding,
          child: Wrap(
            spacing: crossAxisSpacing,
            runSpacing: mainAxisSpacing,
            children: List.generate(itemCount, (_) {
              return Container(
                width: itemWidth,
                height: itemHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: borderRadius,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
