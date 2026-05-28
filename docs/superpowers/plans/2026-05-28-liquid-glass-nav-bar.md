# 导航栏 Liquid Glass 效果实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 执行本计划；实现视觉和默认值变更前，先按本计划补齐最小验证。步骤使用复选框（`- [ ]`）语法跟踪进度。

**目标：** 在 PiliPlus 底部导航栏实现参考 `Kyant0/AndroidLiquidGlass` 的 Liquid Glass 视觉效果，并让「设置 > 外观 > 悬浮底栏」对未写入过该设置的新用户默认启用。

**架构：** 当前 PiliPlus 是 Flutter 项目，底部导航已经有 `FloatingNavigationBar` 自定义实现。`AndroidLiquidGlass` 是 Compose Multiplatform Liquid Glass effect library，示例 `LiquidBottomTabs` 使用 `drawBackdrop`、`blur`、`lens`、highlight、shadow、innerShadow 等 Compose 能力。Kotlin / Compose 组件不能原样嵌入 Flutter 导航栏，但 Apache-2.0 允许在保留版权和许可证说明的前提下复用源码算法。因此本计划以源码移植为准：把 `lens` 的圆角矩形 SDF 折射 shader 从 AGSL 移植为 Flutter runtime effect GLSL，再和 Flutter `BackdropFilter` 组合；非 Impeller 后端降级为普通 blur。

**技术栈：** Flutter / Dart、Material 3、现有 `FloatingNavigationBar`、`material_new_shapes`、Flutter `FragmentProgram`、`ImageFilter.shader`、`ImageFilter.compose`、`ImageFilter.blur`、`BackdropFilter`、`flutter_test`。

## 现状依据

- 外观设置项已存在：`lib/pages/setting/models/style_settings.dart` 中 `SettingBoxKey.floatingNavBar` 当前 `defaultVal: false`。
- 偏好读取已存在：`lib/utils/storage_pref.dart` 中 `Pref.floatingNavBar` 当前默认值为 `false`。
- 主页面已接入悬浮底栏：`lib/pages/main/view.dart` 会在 `_mainController.floatingNavBar` 为真时使用 `FloatingNavigationBar`。
- 悬浮底栏现有实现：`lib/common/widgets/floating_navigation_bar.dart` 当前是圆角超椭圆容器 + Material 表面色，没有背景采样模糊和玻璃高光。
- 项目已有 `flutter_test`，但当前测试集中在主题色；本次需要补充导航默认值或组件级 smoke test。
- `AndroidLiquidGlass` 参考点：容器是胶囊形底栏，浅色 / 深色主题使用约 40% 透明容器色，底层有背景模糊，`lens(24.dp, 24.dp)` 负责边缘折射，按压 / 选中态再叠加色散、交互高光、阴影和内阴影。

## 设计边界

- 不引入 Android Compose UI 组件到 Flutter 层；只移植其 shader 算法。
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
- [ ] 加载 `shaders/liquid_glass_refraction.frag`，在支持 `ImageFilter.shader` 的后端组合 `blur -> shader lens`。
- [ ] shader 不可用或非 Impeller 后端时，只降级当前玻璃层，不影响导航栏渲染。

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

    // 使用 ImageFilter.compose(
    //   inner: ImageFilter.blur(...),
    //   outer: ImageFilter.shader(refractionShader),
    // )
    // 保持 AndroidLiquidGlass 中 blur 后接 lens 的效果顺序。
  }
}
```

实现时注意：`shape` 应在调用侧构造为带 `side` 的 `RoundedSuperellipseBorder`，`LiquidGlassSurface` 不需要依赖泛型 `ShapeBorder.copyWith`。

## 任务 3.1：移植 AndroidLiquidGlass 折射 shader

- [ ] 新增 `shaders/liquid_glass_refraction.frag`。
- [ ] 保留原项目版权和 Apache-2.0 许可头。
- [ ] 从 `RoundedRectRefractionShaderString` / `RoundedRectRefractionWithDispersionShaderString` 移植：
  - `radiusAt`
  - `sdRoundedRect`
  - `gradSdRoundedRect`
  - `circleMap`
  - `refractionHeight`
  - `refractionAmount`
  - `chromaticAberration`
- [ ] 按 Flutter `ImageFilter.shader` 要求调整 uniform：
  - 第一个 uniform 必须是 `vec2`，由引擎写入输入纹理尺寸。
  - 第一个 sampler2D 由引擎绑定为 filter input。
  - OpenGLES / Impeller 后端按官方要求翻转 y 轴。
- [ ] 在 `pubspec.yaml` 的 `flutter.shaders` 中声明该 shader。
- [ ] 新增轻量测试确认 shader 资产、版权头和关键算法函数存在。

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
  test/floating_nav_bar_default_test.dart \
  test/floating_navigation_bar_test.dart \
  test/liquid_glass_shader_asset_test.dart

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
- `ImageFilter.shader` 只在 Impeller 后端可用。非支持后端必须运行 blur fallback，不允许崩溃。
- shader uniform 顺序错误会导致运行时滤镜异常；需要依赖 Flutter 编译 / GitHub Actions 进一步验证。
- 如果 `ShapeBorderClipper` 与 `RoundedSuperellipseBorder` 在当前 Flutter 版本表现异常，回退到 `ClipRRect` + 当前 `_kBorderRadius`，先保证稳定。
- 如果测试环境难以初始化 `GStorage`，不要为默认值测试大改存储架构；优先补组件 smoke test，并在人工验证里覆盖新安装默认状态。
- 如果视觉效果仍与 AndroidLiquidGlass 差距明显，下一步应继续移植 highlight、shadow、innerShadow 和交互 pressProgress，而不是回到手绘模拟。

## 推荐实施顺序

1. 默认值测试。
2. 默认启用 `floatingNavBar`。
3. 移植折射 shader 并声明到 `pubspec.yaml`。
4. 新增 `LiquidGlassSurface`，组合 blur 和 refraction shader。
5. 接入 `FloatingNavigationBar`。
6. 调整选中指示器透明度和高光。
7. 运行格式化、测试、分析和人工验证。
