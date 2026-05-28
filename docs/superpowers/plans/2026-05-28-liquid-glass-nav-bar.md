# 导航栏 Liquid Glass 效果实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 执行本计划；实现视觉和默认值变更前，先按本计划补齐最小验证。步骤使用复选框（`- [ ]`）语法跟踪进度。

**目标：** 在 PiliPlus 底部导航栏实现参考 `Kyant0/AndroidLiquidGlass` 的 Liquid Glass 视觉效果，并让「设置 > 外观 > 悬浮底栏」对未写入过该设置的新用户默认启用。

**架构：** 当前 PiliPlus 是 Flutter 项目，底部导航已经有 `FloatingNavigationBar` 自定义实现。`AndroidLiquidGlass` 当前仓库 README 标注为 Compose Multiplatform Liquid Glass effect library，且说明库本身不提供高层组件，需要使用方自行创建；示例 `LiquidBottomTabs` 使用 `drawBackdrop`、`blur`、`lens`、highlight、shadow、innerShadow 等 Compose 能力。因此不能直接作为 Flutter 导航栏组件复用，本次应以它的视觉特征为参考，在 Flutter 侧用现有悬浮导航栏、`BackdropFilter`、半透明材质层、高光边缘和主题色适配复刻效果。

**技术栈：** Flutter / Dart、Material 3、现有 `FloatingNavigationBar`、`material_new_shapes`、`ImageFilter.blur`、`BackdropFilter`、`flutter_test`。

## 现状依据

- 外观设置项已存在：`lib/pages/setting/models/style_settings.dart` 中 `SettingBoxKey.floatingNavBar` 当前 `defaultVal: false`。
- 偏好读取已存在：`lib/utils/storage_pref.dart` 中 `Pref.floatingNavBar` 当前默认值为 `false`。
- 主页面已接入悬浮底栏：`lib/pages/main/view.dart` 会在 `_mainController.floatingNavBar` 为真时使用 `FloatingNavigationBar`。
- 悬浮底栏现有实现：`lib/common/widgets/floating_navigation_bar.dart` 当前是圆角超椭圆容器 + Material 表面色，没有背景采样模糊和玻璃高光。
- 项目已有 `flutter_test`，但当前测试集中在主题色；本次需要补充导航默认值或组件级 smoke test。
- `AndroidLiquidGlass` 参考点：容器是胶囊形底栏，浅色 / 深色主题使用约 40% 透明容器色，底层有背景模糊，按压 / 选中态叠加折射、交互高光、阴影和内阴影。

## 设计边界

- 不引入 Android Compose UI 组件到 Flutter 层。
- 不新增跨平台不一致的 Android-only 导航栏实现。
- 不重写 `MainApp` 主导航架构；只改悬浮导航栏的视觉壳和默认设置。
- 不强行覆盖老用户显式保存过的 `floatingNavBar` 值；只改变未写入设置时的默认值。
- 保留 `MD3样式底栏`、`useSideBar`、平板侧栏和隐藏底栏逻辑。

## 任务 1：补充默认值验证

目标是先锁定“新用户默认启用，老用户显式关闭不被覆盖”的行为。

- [ ] 检查 `GStorage.setting.get` 在测试环境中的初始化方式，确认是否可以直接测 `Pref.floatingNavBar`。
- [ ] 如果现有存储初始化成本低，新增偏好测试；否则至少新增静态默认值测试，覆盖设置模型和 `Pref` 默认值所在文件。
- [ ] 测试命名建议：
  - `test/floating_nav_bar_default_test.dart`
  - 或合并到现有轻量测试文件中，避免拉起完整 App。

期望验证点：

```dart
test('floating navigation bar defaults to enabled for fresh settings', () {
  // 新安装 / 未写入 SettingBoxKey.floatingNavBar 时，应读取为 true。
});

test('floating navigation bar setting model uses the same default', () {
  // 外观设置页开关默认值也应为 true，避免 UI 展示与实际读取不一致。
});
```

## 任务 2：默认启用「悬浮底栏」

- [ ] 修改 `lib/utils/storage_pref.dart`：

```dart
static bool get floatingNavBar =>
    _setting.get(SettingBoxKey.floatingNavBar, defaultValue: true);
```

- [ ] 修改 `lib/pages/setting/models/style_settings.dart`：

```dart
const SwitchModel(
  title: '悬浮底栏',
  leading: Icon(MdiIcons.soundbar),
  setKey: SettingBoxKey.floatingNavBar,
  defaultVal: true,
  needReboot: true,
),
```

- [ ] 不写迁移脚本，不主动 `put` 默认值；这样已有用户如果手动关闭过仍保持关闭，未写入过该 key 的用户才使用新默认。

## 任务 3：抽出 Liquid Glass 视觉壳

新增一个小型可复用组件，避免把滤镜、渐变、高光和阴影全部堆在 `FloatingNavigationBar.build` 内。

- [ ] 新增 `lib/common/widgets/liquid_glass_surface.dart`。
- [ ] 组件只负责视觉表面，不处理导航选择状态。
- [ ] 支持传入 `shape`、`borderRadius`、`child`、可选 `backgroundColor`。
- [ ] 使用主题亮暗色调整透明度和高光，避免深色主题下发灰、浅色主题下过曝。

建议结构：

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    required this.shape,
    this.blurSigma = 18,
    this.backgroundColor,
  });

  final Widget child;
  final ShapeBorder shape;
  final double blurSigma;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = backgroundColor ?? colorScheme.surface;
    final fillColor = baseColor.withValues(alpha: isDark ? 0.46 : 0.58);
    final strokeColor = Colors.white.withValues(alpha: isDark ? 0.12 : 0.46);

    return PhysicalShape(
      clipper: ShapeBorderClipper(shape: shape),
      color: Colors.transparent,
      elevation: isDark ? 2 : 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: fillColor,
              shape: shape,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    strokeColor,
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                shape: shape,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
```

实现时注意：`shape` 应在调用侧构造为带 `side` 的 `RoundedSuperellipseBorder`，`LiquidGlassSurface` 不需要依赖泛型 `ShapeBorder.copyWith`。

## 任务 4：接入到 `FloatingNavigationBar`

- [ ] 在 `lib/common/widgets/floating_navigation_bar.dart` 引入 `LiquidGlassSurface`。
- [ ] 保持 `_kNavigationHeight`、`_kIndicatorWidth`、`_kIndicatorPadding` 不变，避免导航尺寸和隐藏动画发生漂移。
- [ ] 将当前 `DecoratedBox` 外壳替换为 `LiquidGlassSurface`，内部 `Padding` 和 `Row` 结构保持原样。
- [ ] `backgroundColor` 参数仍生效，作为玻璃填充的基色。
- [ ] 选中态 `NavigationIndicator` 改为半透明玻璃内高亮，而不是完全不透明色块。

建议替换点：

```dart
child: LiquidGlassSurface(
  shape: RoundedSuperellipseBorder(
    side: defaults.borderSide,
    borderRadius: _kBorderRadius,
  ),
  backgroundColor: backgroundColor ??
      navigationBarTheme.backgroundColor ??
      defaults.backgroundColor!,
  child: Padding(
    padding: _kIndicatorPadding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 保留现有 destination 构建逻辑
      ],
    ),
  ),
),
```

选中指示器建议：

```dart
final indicatorBase = info.indicatorColor ??
    navigationBarTheme.indicatorColor ??
    defaults.indicatorColor!;

NavigationIndicator(
  animation: animation,
  color: indicatorBase.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.34),
),
```

如果视觉太弱，再在 `NavigationIndicator` 内部增加一层细边框或顶部高光；不要先改导航布局。

## 任务 5：视觉细节与性能约束

- [ ] 模糊半径从 `sigma = 18` 起步；如果 Android 真机滚动掉帧，降到 `12` 或按平台降级。
- [ ] `BackdropFilter` 必须被 `ClipPath` 限制到导航栏形状内，避免全屏模糊开销。
- [ ] 保持 `Scaffold(extendBody: true)` 现状，确保内容能在导航栏后方滚动并被玻璃采样。
- [ ] 检查底部安全区和 `bottomPadding`，不要让玻璃栏压住系统手势区域。
- [ ] 深色主题下玻璃层需要更低高光、更高背景透明度；浅色主题下避免白底不可见。

## 任务 6：验证

实现后运行：

```bash
dart format lib/common/widgets/liquid_glass_surface.dart \
  lib/common/widgets/floating_navigation_bar.dart \
  lib/pages/setting/models/style_settings.dart \
  lib/utils/storage_pref.dart \
  test/floating_nav_bar_default_test.dart

flutter test
flutter analyze
```

人工验证：

- [ ] 清空或使用新设置存储启动 App，底部默认显示悬浮导航栏。
- [ ] 进入「设置 > 外观」，「悬浮底栏」开关默认打开。
- [ ] 手动关闭「悬浮底栏」并重启，确认不会被默认值重新打开。
- [ ] 首页、动态、我的三栏切换时，选中指示器动画正常。
- [ ] 滚动列表经过底部导航后方时，玻璃模糊能采样到底部内容。
- [ ] 深色 / 浅色主题下文本、图标和选中态均可读。
- [ ] 开启隐藏底栏时，滑出 / 滑入动画仍正常。
- [ ] 平板横屏或侧边栏模式不受影响。

## 风险与回退

- `BackdropFilter` 在低端 Android 设备上可能有额外 GPU 开销。回退方式：降低 `blurSigma`，或只保留半透明填充和高光边框。
- 如果 `ShapeBorderClipper` 与 `RoundedSuperellipseBorder` 在当前 Flutter 版本表现异常，回退到 `ClipRRect` + 当前 `_kBorderRadius`，先保证稳定。
- 如果测试环境难以初始化 `GStorage`，不要为默认值测试大改存储架构；优先补组件 smoke test，并在人工验证里覆盖新安装默认状态。
- 如果视觉效果与 AndroidLiquidGlass 差距仍明显，再单独开一个 shader / fragment program spike；不要在本次导航栏改造里直接引入高风险渲染管线。

## 推荐实施顺序

1. 默认值测试。
2. 默认启用 `floatingNavBar`。
3. 新增 `LiquidGlassSurface`。
4. 接入 `FloatingNavigationBar`。
5. 调整选中指示器透明度和高光。
6. 运行格式化、测试、分析和人工验证。
