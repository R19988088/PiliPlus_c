# 封面长按弹窗播放入口实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 执行本计划；实现前先补齐最小验证，实施过程中按复选框（`- [ ]`）更新进度。

**目标：** 给首页视频卡片和动态视频封面长按弹窗增加“播放”按钮；点击弹窗下方视频信息时进入原视频详情页；弹窗内播放也支持长按快进。

**架构：** 当前首页卡片和动态卡片的封面长按都汇聚到 `imageSaveDialog`。本次应扩展这个共用弹窗能力，由各调用方传入“打开详情”和“播放预览”的回调，避免在弹窗里反向猜测业务来源。播放能力优先复用现有 `pl_player` / `PLVideoPlayer` / `PlPlayerController.setLongPressStatus`，只在现有播放器视图无法直接嵌入弹窗时抽出轻量预览组件。

**技术栈：** Flutter / Dart、GetX、`flutter_smart_dialog`、`media_kit_video`、现有 `pl_player`、`flutter_test`。

## 现状依据

- 首页竖向视频卡片在 `lib/common/widgets/video_card/video_card_v.dart`，长按调用 `imageSaveDialog(title, cover, bvid)`；点击卡片走 `onPushDetail()`，其中普通视频最终调用 `PageUtils.toVideoPage(...)`。
- 横向视频卡片在 `lib/common/widgets/video_card/video_card_h.dart`，也复用 `imageSaveDialog(...)`；虽然需求点名首页和动态，但这个共享入口应一起纳入，避免同一种封面长按弹窗行为不一致。
- 动态主卡片在 `lib/pages/dynamics/widgets/dynamic_panel.dart`，长按 `_imageSaveDialog(...)` 会从 `DYNAMIC_TYPE_AV`、`DYNAMIC_TYPE_UGC_SEASON`、`DYNAMIC_TYPE_PGC_UNION` 等类型提取标题、封面、`bvid` 后调用 `imageSaveDialog(...)`；点击动态本身走 `PageUtils.pushDynDetail(item)`。
- 转发动态在 `lib/pages/dynamics/widgets/forward_panel.dart`，长按同样提取 `title`、`cover`、`bvid` 后调用 `imageSaveDialog(...)`；点击内容走 `PageUtils.pushDynDetail(orig)`。
- 弹窗实现集中在 `lib/common/widgets/image/image_save.dart`，当前只有关闭、稍后再看、分享、保存封面图，封面点击会直接关闭弹窗。
- 详情页跳转工具在 `lib/utils/page_utils.dart`。动态详情跳转已封装在 `PageUtils.pushDynDetail(...)`，视频详情跳转已封装在 `PageUtils.toVideoPage(...)`。
- 触摸长按快进已有实现：`lib/plugin/pl_player/view/view.dart` 内部使用 `LongPressGestureRecognizer` 调 `plPlayerController.setLongPressStatus(true/false)`；`lib/plugin/pl_player/controller.dart` 会在长按时切换倍速，松手恢复；播放器视图已有“倍速中”提示。

## 设计边界

- 不在 `imageSaveDialog` 内根据 `bvid` 自行猜测所有来源；调用方负责传入打开详情和播放预览回调。
- 不改变首页卡片、动态卡片原有点击行为；弹窗信息点击只复用相同的跳转路径。
- 不为播放按钮新增全局路由；弹窗播放应是当前长按弹窗中的预览能力，进入详情页由视频信息点击承担。
- 不把完整 `VideoDetailPageV` 嵌入弹窗；只复用播放器和取流逻辑需要的最小部分。
- PGC、课程、直播等非普通视频类型只在现有数据和播放器接口明确支持时开放播放按钮；否则只保留进入详情和封面操作。
- 弹窗关闭时必须释放预览播放器资源，不影响主播放器实例、后台音频和画中画状态。

## 任务 1：补齐最小测试保护

- [ ] 阅读 `imageSaveDialog` 的可测试方式，确认 `SmartDialog` 在 widget test 中的挂载模式。
- [ ] 新增或扩展弹窗测试，建议文件：`test/common/widgets/image_save_dialog_test.dart`。
- [ ] 覆盖“传入播放回调时显示播放按钮，点击后调用回调”。
- [ ] 覆盖“传入详情回调时标题 / 信息区域可点击，点击后先关闭弹窗再调用详情回调”。
- [ ] 覆盖“不传播放回调时不显示播放按钮”，避免直播、图片动态等非视频类型错误出现播放入口。

期望测试形态：

```dart
imageSaveDialog(
  title: 'title',
  cover: 'cover',
  bvid: 'BV...',
  onOpenDetail: onOpenDetail,
  onPlay: onPlay,
);
```

## 任务 2：扩展 `imageSaveDialog` 的通用动作能力

- [ ] 修改 `lib/common/widgets/image/image_save.dart`，给 `imageSaveDialog` 增加可选参数：

```dart
VoidCallback? onOpenDetail,
VoidCallback? onPlay,
```

- [ ] 在弹窗标题 / 视频信息区域外层加 `InkWell` 或 `GestureDetector`；当 `onOpenDetail != null` 时，点击后执行：

```dart
SmartDialog.dismiss();
onOpenDetail();
```

- [ ] 在操作按钮区增加播放按钮：

```dart
if (onPlay != null)
  iconButton(
    iconSize: iconSize,
    tooltip: '播放',
    onPressed: () {
      SmartDialog.dismiss();
      onPlay();
    },
    icon: const Icon(Icons.play_arrow_rounded),
  ),
```

- [ ] 播放按钮位置放在“稍后再看”之前，保证视频动作优先于封面保存动作。
- [ ] 保持 `aid` / `bvid` 的稍后再看逻辑不变。
- [ ] 保持不传新参数的所有旧调用行为不变。

## 任务 3：实现弹窗播放预览入口

- [ ] 新增轻量播放预览组件，建议路径：`lib/common/widgets/video_preview/cover_video_preview_sheet.dart`。
- [ ] 组件输入只接收播放所需的最小视频标识和展示信息：

```dart
class CoverVideoPreviewData {
  const CoverVideoPreviewData({
    this.aid,
    this.bvid,
    this.cid,
    this.cover,
    this.title,
    this.isVertical = false,
    this.dimension,
  });

  final dynamic aid;
  final String? bvid;
  final int? cid;
  final String? cover;
  final String? title;
  final bool isVertical;
  final Dimension? dimension;
}
```

- [ ] 如果已有类型能承载这些字段，优先复用已有类型；只有复用会污染来源模型时才新增 `CoverVideoPreviewData`。
- [ ] 播放预览负责：
  - 需要 `cid` 但来源未给出时，复用 `SearchHttp.ab2cWithDimension(...)` 查询。
  - 复用 `VideoHttp.videoUrl(...)` 取流，不复制 `VideoDetailController.queryVideoUrl(...)` 的全部页面逻辑。
  - 从返回的 DASH / durl 中按现有 `VideoDetailController` 选择规则取可播放 `videoUrl` / `audioUrl`。
  - 用 `PlPlayerController.setDataSource(NetworkSource(...))` 初始化播放。
  - 用现有 `PLVideoPlayer` 显示视频；如果 `PLVideoPlayer` 对 `VideoDetailController` 依赖太重，则拆出一个只包含 `VideoController`、基础手势和倍速提示的预览播放器。
- [ ] 弹窗关闭、预览关闭或组件 `dispose` 时释放预览用 `PlPlayerController`，并确认不会 dispose 当前详情页播放器。

## 任务 4：复用长按快进能力

- [ ] 先尝试直接复用 `PLVideoPlayer` 内部现有长按识别，因为它已经在 `lib/plugin/pl_player/view/view.dart` 调用了 `setLongPressStatus(true/false)` 并显示倍速提示。
- [ ] 如果预览播放器不能直接用 `PLVideoPlayer`，新增一个小组件，建议路径：`lib/plugin/pl_player/widgets/long_press_speed_overlay.dart`。
- [ ] 新组件只负责长按倍速手势和提示，不处理详情页独有的弹幕、选集、亮度、音量、全屏面板。
- [ ] 组件逻辑必须复用 `PlPlayerController.setLongPressStatus(true/false)`，不要重新实现倍速恢复逻辑。
- [ ] 将 `PLVideoPlayer` 和预览播放器都接到同一个长按倍速组件，避免以后两处行为漂移。
- [ ] 手动验证长按时倍速提示出现，松手恢复原倍速，视频结束或暂停时长按不误切倍速。

## 任务 5：首页卡片接入

- [ ] 修改 `lib/common/widgets/video_card/video_card_v.dart`。
- [ ] `onLongPress` 调用 `imageSaveDialog(...)` 时传入：
  - `onOpenDetail: onPushDetail`
  - 普通 `goto == 'av'` 时传入 `onPlay`，打开 `CoverVideoPreviewSheet`
  - `goto == 'bangumi'`、`picture`、其他 scheme 类型先不显示播放按钮，除非实现时明确支持对应取流
- [ ] 播放预览的数据从 `videoItem.aid`、`videoItem.bvid`、`videoItem.cid`、`videoItem.cover`、`videoItem.title`、`uri.isVerticalFromUri`、`SearchHttp.ab2cWithDimension(...)` 结果中取得。
- [ ] 修改 `lib/common/widgets/video_card/video_card_h.dart`，按相同方式传入 `onOpenDetail` 和普通视频 `onPlay`，保持共享弹窗一致。

## 任务 6：动态和转发动态接入

- [ ] 修改 `lib/pages/dynamics/widgets/dynamic_panel.dart`。
- [ ] `_imageSaveDialog(...)` 在能提取视频或番剧目标时传入 `onOpenDetail: () => PageUtils.pushDynDetail(item)`。
- [ ] 对 `DYNAMIC_TYPE_AV` 和 `DYNAMIC_TYPE_UGC_SEASON`，在 `bvid` 非空时传入 `onPlay`。
- [ ] 对 `DYNAMIC_TYPE_PGC` / `DYNAMIC_TYPE_PGC_UNION`，先只传入进入详情；只有确认 `epId`、`seasonId`、`cid`、`VideoHttp.videoUrl(...)` 参数齐全后再开放播放按钮。
- [ ] 修改 `lib/pages/dynamics/widgets/forward_panel.dart`，对 `orig` 使用同样策略：
  - `onOpenDetail: () => PageUtils.pushDynDetail(orig)`
  - `DYNAMIC_TYPE_AV` / `DYNAMIC_TYPE_UGC_SEASON` 且 `bvid` 非空时开放播放。
- [ ] 保留原来的 `morePanel(context)` fallback，不影响不支持封面保存的动态类型。

## 任务 7：交互细节

- [ ] 播放按钮点击后关闭封面保存弹窗，再打开播放预览弹窗 / bottom sheet，避免双层 `SmartDialog` 手势冲突。
- [ ] 视频信息点击后关闭封面保存弹窗，再跳详情页，避免详情页被遮罩盖住。
- [ ] 播放预览顶部显示标题和关闭按钮；不要把标题做成说明文案。
- [ ] 预览底部只保留基础播放控制和进度，更多操作仍由详情页承担。
- [ ] 预览失败时显示错误提示，并保留“进入详情”作为兜底。
- [ ] 桌面端右键触发的同一弹窗也应拥有相同播放 / 详情行为。

## 任务 8：验证

实现后运行：

```bash
dart format \
  lib/common/widgets/image/image_save.dart \
  lib/common/widgets/video_card/video_card_v.dart \
  lib/common/widgets/video_card/video_card_h.dart \
  lib/pages/dynamics/widgets/dynamic_panel.dart \
  lib/pages/dynamics/widgets/forward_panel.dart \
  lib/common/widgets/video_preview/cover_video_preview_sheet.dart \
  test/common/widgets/image_save_dialog_test.dart

flutter test test/common/widgets/image_save_dialog_test.dart
flutter analyze
```

人工验证：

- [ ] 首页普通视频卡片长按：弹窗出现播放按钮；点播放能在弹窗预览中播放；长按画面能快进，松手恢复。
- [ ] 首页普通视频卡片长按：点标题 / 信息区域进入原视频详情页。
- [ ] 动态普通视频长按：弹窗出现播放按钮；点播放能预览；点信息区域进入原动态对应的视频详情页。
- [ ] 转发动态普通视频长按：播放和进入详情都指向被转发的原视频。
- [ ] 番剧 / 课程 / 直播 / 图片动态：不支持弹窗播放时不出现播放按钮；能进入详情的仍可通过信息区域进入原详情。
- [ ] 分享、保存封面图、稍后再看功能保持原行为。
- [ ] 关闭预览后原页面滚动、主播放器、画中画状态不异常。
