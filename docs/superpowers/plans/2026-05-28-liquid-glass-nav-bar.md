# 导航栏 Liquid Glass 效果实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 执行本计划；实现视觉和默认值变更前，先按本计划补齐最小验证。步骤使用复选框（`- [ ]`）语法跟踪进度。

**目标：** 在 PiliPlus 底部导航栏实现参考 `Kyant0/AndroidLiquidGlass` 的 Liquid Glass 视觉效果，并让「设置 > 外观 > 悬浮底栏」对未写入过该设置的新用户默认启用。

**架构：** 当前 PiliPlus 是 Flutter 项目，底部导航已经有 `FloatingNavigationBar` 自定义实现。用户指定直接使用 `liquid_glass_widgets`，因此不再维护项目内自定义 shader 移植；本次用 package 的 `GlassContainer` 替换悬浮导航栏外壳，同时在 app 启动时调用 `LiquidGlassWidgets.initialize()` 并用 `LiquidGlassWidgets.wrap()` 包住根组件。

**技术栈：** Flutter / Dart、Material 3、现有 `FloatingNavigationBar`、`material_new_shapes`、`liquid_glass_widgets`、`flutter_test`。

## 现状依据

- 外观设置项已存在：`lib/pages/setting/models/style_settings.dart` 中 `SettingBoxKey.floatingNavBar` 当前 `defaultVal: false`。
- 偏好读取已存在：`lib/utils/storage_pref.dart` 中 `Pref.floatingNavBar` 当前默认值为 `false`。
- 主页面已接入悬浮底栏：`lib/pages/main/view.dart` 会在 `_mainController.floatingNavBar` 为真时使用 `FloatingNavigationBar`。
- 悬浮底栏现有实现：`lib/common/widgets/floating_navigation_bar.dart` 当前是圆角超椭圆容器 + Material 表面色，没有背景采样模糊和玻璃高光。
- 项目已有 `flutter_test`，但当前测试集中在主题色；本次需要补充导航默认值或组件级 smoke test。
- `liquid_glass_widgets` 提供 `GlassContainer`、`LiquidGlassSettings` 和 `LiquidRoundedSuperellipse`，可以承载现有导航栏的内容与尺寸。

## 设计边界

- 不引入 Android Compose UI 组件到 Flutter 层。
- 不保留项目内自定义 `shaders/liquid_glass_refraction.frag`，避免和 package 的渲染管线并存。
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

## 任务 3：接入 `liquid_glass_widgets`

- [ ] 在 `pubspec.yaml` 添加 `liquid_glass_widgets`。
- [ ] 在 `main()` 中调用 `LiquidGlassWidgets.initialize()`。
- [ ] 用 `LiquidGlassWidgets.wrap()` 包住 `MyApp`，日志开启和关闭两条启动路径保持一致。
- [ ] 在 `GetMaterialApp.builder` 内加入 `GlassBackdropScope`，避免页面切换时旧页面 backdrop 残留。
- [ ] 保留 `lib/common/widgets/liquid_glass_surface.dart` 作为项目内适配层，但内部使用 package 的 `GlassContainer`。
- [ ] 删除自定义 shader 文件、NOTICE 和对应测试。

## 任务 4：适配 `LiquidGlassSurface`

- [ ] 组件只负责视觉表面，不处理导航选择状态。
- [ ] 支持传入 `shape`、`child`、可选 `backgroundColor`。
- [ ] 使用主题亮暗色调整透明度和高光，避免深色主题下发灰、浅色主题下过曝。
- [ ] 用 `LiquidRoundedSuperellipse` 映射现有 `RoundedSuperellipseBorder` 的胶囊半径。
- [ ] 用 `LiquidGlassSettings` 设置 blur、厚度、色散、折射率、饱和度和光照。

## 任务 5：接入到 `FloatingNavigationBar`

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

## 任务 6：视觉细节与性能约束

- [ ] `LiquidGlassWidgets.wrap()` 使用 `adaptiveQuality: true`，根主题先用 `GlassQuality.standard`，底部导航栏用 `GlassQuality.premium`。
- [ ] 保持 `Scaffold(extendBody: true)` 现状，确保内容能在导航栏后方滚动并被玻璃采样。
- [ ] 检查底部安全区和 `bottomPadding`，不要让玻璃栏压住系统手势区域。
- [ ] 深色主题下玻璃层需要更低高光、更高背景透明度；浅色主题下避免白底不可见。

## 任务 7：验证

实现后运行：

```bash
dart format lib/common/widgets/liquid_glass_surface.dart \
  lib/main.dart \
  lib/common/widgets/floating_navigation_bar.dart \
  lib/pages/setting/models/style_settings.dart \
  lib/utils/storage_pref.dart \
  test/floating_nav_bar_default_test.dart \
  test/floating_navigation_bar_test.dart \
  test/liquid_glass_widgets_package_test.dart

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

- 新增 package 可能带来锁文件变更，需要由 `flutter pub get` 生成。
- `GlassContainer` 的 API 若变动，优先按 pub.dev 最新文档调整，不回退到自维护 shader。
- 如果 `LiquidRoundedSuperellipse` 与现有 `RoundedSuperellipseBorder` 的曲线有细微差异，优先保持现有导航尺寸和触控结构。
- 如果测试环境难以初始化 `GStorage`，不要为默认值测试大改存储架构；优先补组件 smoke test，并在人工验证里覆盖新安装默认状态。

## 推荐实施顺序

1. 默认值测试。
2. 默认启用 `floatingNavBar`。
3. 添加 `liquid_glass_widgets` 并初始化。
4. 用 `GlassContainer` 改造 `LiquidGlassSurface`。
5. 接入 `FloatingNavigationBar`。
6. 删除自维护 shader 资产和测试。
7. 运行格式化、测试、分析和人工验证。
