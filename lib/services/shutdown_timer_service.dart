// 定时关闭服务
import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/menu_row.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

enum _ShutdownType with EnumWithLabel {
  pause('暂停视频'),
  exit('退出APP'),
  ;

  @override
  final String label;
  const _ShutdownType(this.label);
}

final shutdownTimerService = ShutdownTimerService._internal();

class ShutdownTimerService {
  ShutdownTimerService._internal();

  VoidCallback? onPause;
  ValueGetter<bool>? isPlaying;

  Timer? _shutdownTimer;
  bool get isActive => _shutdownTimer?.isActive ?? false;
  int _durationInMinutes = 0;
  _ShutdownType _shutdownType = .pause;

  bool _isWaiting = false;
  bool get isWaiting => _isWaiting;
  bool _waitUntilCompleted = false;
  double _hourDragOffset = 0;
  double _minuteDragOffset = 0;

  void _stopTimer() {
    if (_shutdownTimer != null) {
      _shutdownTimer!.cancel();
      _shutdownTimer = null;
    }
  }

  void reset([int durationInMinutes = 0]) {
    _stopTimer();
    _isWaiting = false;
    _durationInMinutes = durationInMinutes;
  }

  void _startShutdownTimer(int durationInMinutes) {
    reset(durationInMinutes);
    if (durationInMinutes == 0) {
      SmartDialog.showToast('取消定时关闭');
      return;
    }
    SmartDialog.showToast('设置 ${_format(durationInMinutes)} 后定时关闭');
    _shutdownTimer = Timer(
      Duration(minutes: durationInMinutes),
      _handleShutdown,
    );
  }

  void _handleShutdown() {
    switch (_shutdownType) {
      case _ShutdownType.pause:
        late final player = PlPlayerController.instance;
        final isPlaying =
            this.isPlaying?.call() ?? player?.playerStatus.isPlaying ?? false;
        if (isPlaying) {
          if (_waitUntilCompleted) {
            _isWaiting = true;
          } else {
            _durationInMinutes = 0;
            (onPause ?? player?.pause)?.call();
            SmartDialog.showToast('定时时间已到，已暂停');
          }
        }
      case _ShutdownType.exit:
        if (_waitUntilCompleted) {
          final isPlaying =
              this.isPlaying?.call() ??
              PlPlayerController.instance?.playerStatus.isPlaying ??
              false;
          if (isPlaying) {
            _isWaiting = true;
            return;
          }
        }
        _syncProgressAndExit();
    }
  }

  void handleWaiting() {
    switch (_shutdownType) {
      case _ShutdownType.pause:
        _isWaiting = false;
        _durationInMinutes = 0;
        SmartDialog.showToast('定时时间已到，已暂停');
      case _ShutdownType.exit:
        _syncProgressAndExit();
    }
  }

  void _syncProgressAndExit() {
    if (PlPlayerController.instance case final player?) {
      final res = player.makeHeartBeat(
        player.positionSeconds.value,
        type: .completed,
        isManual: true,
      );
      if (res != null) {
        res.whenComplete(() => exit(0));
        return;
      }
    }
    exit(0);
  }

  static (int hour, int minute) _parseMinutes(int minutes) =>
      (minutes ~/ 60, minutes % 60);

  static String _format(int minutes) {
    if (minutes == 60) return '60分钟';
    final (int hour, int minute) = _parseMinutes(minutes);
    if (hour > 0 && minute > 0) {
      return '$hour小时$minute分钟';
    } else if (hour > 0) {
      return '$hour小时';
    } else {
      return '$minute分钟';
    }
  }

  void _adjustCustomDuration({
    int hours = 0,
    int minutes = 0,
  }) {
    final duration = (_durationInMinutes + hours * 60 + minutes * 15)
        .clamp(
          0,
          23 * 60 + 45,
        )
        .toInt();
    reset(duration);
  }

  Widget _buildInlineTimePicker(
    ThemeData theme,
    void Function(void Function()) setState,
  ) {
    const dragStep = 28.0;

    void handleDrag({
      required double delta,
      required bool isHour,
    }) {
      var offset = isHour ? _hourDragOffset : _minuteDragOffset;
      offset += delta;
      while (offset.abs() >= dragStep) {
        final direction = offset < 0 ? 1 : -1;
        setState(() {
          _adjustCustomDuration(
            hours: isHour ? direction : 0,
            minutes: isHour ? 0 : direction,
          );
        });
        offset += offset < 0 ? dragStep : -dragStep;
      }
      if (isHour) {
        _hourDragOffset = offset;
      } else {
        _minuteDragOffset = offset;
      }
    }

    final (hour, minute) = _parseMinutes(_durationInMinutes);
    final timeStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      height: 1,
    );
    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
    final cardDecoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    );

    Widget timeColumn({
      required String value,
      required String label,
      required bool isHour,
    }) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) => handleDrag(
            delta: details.primaryDelta ?? 0,
            isHour: isHour,
          ),
          onVerticalDragEnd: (_) {
            if (isHour) {
              _hourDragOffset = 0;
            } else {
              _minuteDragOffset = 0;
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: cardDecoration,
                child: SizedBox(
                  height: 72,
                  child: Center(
                    child: Text(value, style: timeStyle),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          timeColumn(
            value: hour.toString().padLeft(2, '0'),
            label: '小时',
            isHour: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(':', style: timeStyle),
          ),
          timeColumn(
            value: minute.toString().padLeft(2, '0'),
            label: '分钟',
            isHour: false,
          ),
        ],
      ),
    );
  }

  void showScheduleExitDialog(
    BuildContext context, {
    required bool isFullScreen,
    bool isLive = false,
  }) {
    const TextStyle titleStyle = TextStyle(fontSize: 14);
    const TextStyle buttonStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    if (isLive) {
      _waitUntilCompleted = false;
    }
    PageUtils.showVideoBottomSheet(
      context,
      isFullScreen: () => isFullScreen,
      child: StatefulBuilder(
        builder: (_, setState) {
          final ThemeData theme = Theme.of(context);
          return Theme(
            data: theme,
            child: Padding(
              padding: const .all(12),
              child: Material(
                elevation: 12,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.22),
                clipBehavior: Clip.antiAlias,
                color: theme.colorScheme.surface,
                borderRadius: const .all(.circular(12)),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const .symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const .symmetric(horizontal: 16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Center(
                                child: Text('定时关闭', style: titleStyle),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    padding: const .symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                  onPressed: _durationInMinutes == 0
                                      ? null
                                      : () {
                                          _startShutdownTimer(
                                            _durationInMinutes,
                                          );
                                          Navigator.pop(context);
                                        },
                                  child: const Text(
                                    '开始定时播放',
                                    style: buttonStyle,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const .symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                  onPressed: () {
                                    reset();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    '取消',
                                    style: buttonStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInlineTimePicker(theme, setState),
                        if (!isLive) ...[
                          Builder(
                            builder: (context) {
                              void onChanged([_]) {
                                _waitUntilCompleted = !_waitUntilCompleted;
                                (context as Element).markNeedsBuild();
                              }

                              return InkWell(
                                onTap: onChanged,
                                child: Padding(
                                  padding: const .symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          '额外等待视频播放完毕',
                                          style: titleStyle,
                                        ),
                                      ),
                                      Transform.scale(
                                        alignment: Alignment.centerRight,
                                        scale: 0.8,
                                        child: Switch(
                                          value: _waitUntilCompleted,
                                          onChanged: onChanged,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 5),
                        Padding(
                          padding: const .only(left: 18),
                          child: Builder(
                            builder: (context) {
                              return Row(
                                spacing: 12,
                                children: [
                                  const Text('倒计时结束:', style: titleStyle),
                                  ..._ShutdownType.values.map(
                                    (e) => ActionRowLineItem(
                                      onTap: () {
                                        _shutdownType = e;
                                        (context as Element).markNeedsBuild();
                                      },
                                      text: ' ${e.label} ',
                                      selectStatus: _shutdownType == e,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
