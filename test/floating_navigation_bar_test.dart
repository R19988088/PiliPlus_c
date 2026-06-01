import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
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
    int? doubleTappedIndex;
    int? longPressedIndex;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(
              selectedIndex: 0,
              onDestinationDoubleTap: (index) => doubleTappedIndex = index,
              onDestinationLongPress: (index) => longPressedIndex = index,
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
    expect(doubleTappedIndex, 0);

    await tester.longPress(hitZones.at(1));
    await tester.pump();
    expect(longPressedIndex, 1);
  });
}
