import 'dart:io';

import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:PiliPlus/common/widgets/nav_tap_feedback_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  test('可刷新主导航页面接入单击反馈过渡', () {
    final rcmdView = File('lib/pages/rcmd/view.dart').readAsStringSync();
    final dynamicsTabView = File(
      'lib/pages/dynamics_tab/view.dart',
    ).readAsStringSync();
    final mainController = File(
      'lib/pages/main/controller.dart',
    ).readAsStringSync();
    final mainView = File('lib/pages/main/view.dart').readAsStringSync();

    for (final view in [rcmdView, dynamicsTabView]) {
      expect(view, contains('NavTapFeedbackTransition'));
      expect(view, contains('navTapFeedbackProgress.value'));
    }
    expect(mainController, contains('startNavTapFeedback'));
    expect(mainController, contains('endNavTapFeedback'));
    expect(mainController, contains('cancelNavTapFeedback'));
    expect(mainView, contains('onDestinationPressStart'));
    expect(mainView, contains('onDestinationPressEnd'));
    expect(mainView, contains('onDestinationPressCancel'));
  });

  testWidgets('导航单击反馈按进度下压并在释放后回弹', (tester) async {
    await tester.pumpWidget(
      const NavTapFeedbackTransition(
        progress: 0,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    expect(_translateY(tester), 0);

    await tester.pumpWidget(
      const NavTapFeedbackTransition(
        progress: 0.5,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    await tester.pump();
    expect(_translateY(tester), closeTo(25, 0.01));

    await tester.pumpWidget(
      const NavTapFeedbackTransition(
        progress: 0,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    await tester.pump(const Duration(milliseconds: 252));
    expect(_translateY(tester), greaterThan(0));

    await tester.pumpAndSettle();
    expect(_translateY(tester), closeTo(0, 0.01));
  });

  testWidgets('悬浮底栏渲染液态玻璃背景滤镜层', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Stack(
            children: [
              const ColoredBox(color: Colors.blue),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingNavigationBar(
                  destinations: const [
                    FloatingNavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '首页',
                    ),
                    FloatingNavigationDestination(
                      icon: Icon(Icons.dynamic_feed_outlined),
                      selectedIcon: Icon(Icons.dynamic_feed),
                      label: '动态',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(GlassBottomBar), findsOneWidget);
    expect(find.text('首页'), findsNothing);
    expect(find.text('动态'), findsNothing);
  });

  testWidgets('悬浮底栏支持双击和长按手势回调', (tester) async {
    int? tappedIndex;
    int? doubleTappedIndex;
    int? longPressedIndex;
    int? pressStartedIndex;
    int? pressEndedIndex;
    int? pressCanceledIndex;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) => tappedIndex = index,
              onDestinationDoubleTap: (index) => doubleTappedIndex = index,
              onDestinationLongPress: (index) => longPressedIndex = index,
              onDestinationPressStart: (index) => pressStartedIndex = index,
              onDestinationPressEnd: (index) => pressEndedIndex = index,
              onDestinationPressCancel: (index) => pressCanceledIndex = index,
              destinations: const [
                FloatingNavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '首页',
                ),
                FloatingNavigationDestination(
                  icon: Icon(Icons.dynamic_feed_outlined),
                  selectedIcon: Icon(Icons.dynamic_feed),
                  label: '动态',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final hitZones = find.byType(RawGestureDetector);
    expect(hitZones, findsNWidgets(2));

    await tester.doubleTap(hitZones.first);
    await tester.pump();
    expect(tappedIndex, 0);
    expect(doubleTappedIndex, 0);
    expect(pressStartedIndex, 0);
    expect(pressEndedIndex, 0);

    await tester.longPress(hitZones.at(1));
    await tester.pump();
    expect(longPressedIndex, 1);
    expect(pressStartedIndex, 1);
    expect(pressEndedIndex, 1);
    expect(pressCanceledIndex, isNull);
  });
}

double _translateY(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byType(Transform));
  return transform.transform.getTranslation().y;
}
