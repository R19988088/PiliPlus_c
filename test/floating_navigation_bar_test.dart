import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('悬浮底栏渲染玻璃背景模糊层', (tester) async {
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

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
