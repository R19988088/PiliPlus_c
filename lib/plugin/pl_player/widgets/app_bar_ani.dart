import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:flutter/material.dart';

class AppBarAni extends StatelessWidget {
  const AppBarAni({
    super.key,
    required this.child,
    required this.controller,
    required this.isTop,
    required this.isFullScreen,
    required this.removeSafeArea,
  });

  final Widget child;
  final AnimationController controller;
  final bool isTop;
  final bool isFullScreen;
  final bool removeSafeArea;

  static const fullScreenHorizontalGap = 200.0;
  static const _fullScreenVerticalGap = 5.0;

  static final _topPos = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  );

  static const _topDecoration = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  static final _bottomPos = Tween<Offset>(
    begin: const Offset(0, 1.2),
    end: Offset.zero,
  );

  static const _bottomDecoration = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (isFullScreen) {
      content = Padding(
        padding: EdgeInsets.only(
          top: isTop ? _fullScreenVerticalGap : 0.0,
          bottom: isTop ? 0.0 : _fullScreenVerticalGap,
        ),
        child: content,
      );
      if (!removeSafeArea) {
        content = ViewSafeArea(
          left: false,
          right: false,
          child: content,
        );
      }
    } else if (!removeSafeArea) {
      content = ViewSafeArea(child: content);
    }

    return SlideTransition(
      position: controller.drive(isTop ? _topPos : _bottomPos),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isTop ? _topDecoration : _bottomDecoration,
        ),
        child: isFullScreen
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: fullScreenHorizontalGap,
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}
