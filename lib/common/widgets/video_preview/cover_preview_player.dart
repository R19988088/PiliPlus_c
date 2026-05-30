import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CoverPreviewPlayer extends StatefulWidget {
  const CoverPreviewPlayer({
    super.key,
    required this.cover,
    required this.width,
    required this.height,
    this.aid,
    this.bvid,
    this.cid,
  });

  final String? cover;
  final double width;
  final double height;
  final dynamic aid;
  final String? bvid;
  final int? cid;

  bool get canPlay => aid != null || bvid?.isNotEmpty == true;

  @override
  State<CoverPreviewPlayer> createState() => _CoverPreviewPlayerState();
}

class _CoverPreviewPlayerState extends State<CoverPreviewPlayer> {
  Player? _player;
  VideoController? _controller;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _completedSub;
  bool _playing = false;
  bool _loading = false;
  String? _error;
  int? _cid;
  int _lastHeartBeatProgress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.canPlay) {
      _initPreview();
    }
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _completedSub?.cancel();
    _sendHeartBeat(isManual: true);
    _player?.dispose();
    super.dispose();
  }

  Future<void> _initPreview() async {
    setState(() => _loading = true);
    try {
      final cid = widget.cid ??
          (await SearchHttp.ab2cWithDimension(
            aid: widget.aid,
            bvid: widget.bvid,
          ))?.cid;
      if (!mounted) return;
      if (cid == null) {
        _setError('无法获取视频');
        return;
      }
      _cid = cid;

      final result = await VideoHttp.videoUrl(
        avid: widget.aid,
        bvid: widget.bvid,
        cid: cid,
        tryLook: true,
        videoType: VideoType.ugc,
      );
      if (!mounted) return;
      if (result case Error()) {
        _setError(result.toString());
        return;
      }

      final playUrl = result.data;
      String videoUrl;
      String? audioUrl;
      if (playUrl.dash?.video?.isNotEmpty == true) {
        videoUrl = VideoUtils.getCdnUrl(playUrl.dash!.video!.first.playUrls);
        final audio = playUrl.dash?.audio;
        if (audio?.isNotEmpty == true) {
          audioUrl = VideoUtils.getCdnUrl(audio!.first.playUrls, isAudio: true);
        }
      } else if (playUrl.durl?.isNotEmpty == true) {
        videoUrl = VideoUtils.getCdnUrl(playUrl.durl!.first.playUrls);
      } else {
        _setError('视频资源不存在');
        return;
      }

      final player = await Player.create();
      final controller = await VideoController.create(player);
      if (!mounted) {
        player.dispose();
        return;
      }
      player.setMediaHeader(
        userAgent: BrowserUa.pc,
        referer: HttpString.baseUrl,
      );
      _playingSub = player.stream.playing.listen((playing) {
        if (mounted) setState(() => _playing = playing);
        if (!playing) {
          _sendHeartBeat(isManual: true);
        }
      });
      _positionSub = player.stream.position.listen((position) {
        _sendHeartBeat(progress: position.inSeconds);
      });
      _completedSub = player.stream.completed.listen((completed) {
        if (completed) {
          _sendHeartBeat(progress: -1, isManual: true);
        }
      });
      _player = player;
      _controller = controller;
      await player.open(
        Media(
          videoUrl,
          extras: audioUrl == null
              ? null
              : {'audio-files': '"${_escapeAudioUrl(audioUrl)}"'},
        ),
        play: true,
      );
      if (mounted) setState(() => _loading = false);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('cover preview player error: $e');
        debugPrint(stackTrace.toString());
      }
      if (mounted) _setError('播放失败: $e');
      return;
    }
  }

  Future<void>? _sendHeartBeat({int? progress, bool isManual = false}) {
    if (!widget.canPlay || !Accounts.heartbeat.isLogin || Pref.historyPause) {
      return null;
    }
    final player = _player;
    final cid = _cid ?? widget.cid;
    final currentProgress = progress ?? player?.state.position.inSeconds ?? 0;
    if (cid == null || currentProgress == 0) {
      return null;
    }
    if (currentProgress > 0) {
      final step = isManual ? 2 : 5;
      if (currentProgress - _lastHeartBeatProgress < step) {
        return null;
      }
      _lastHeartBeatProgress = currentProgress;
    }
    final bvid = widget.bvid ??
        (widget.aid is int ? IdUtils.av2bv(widget.aid as int) : null);
    return VideoHttp.heartBeat(
      aid: widget.aid,
      bvid: bvid,
      cid: cid,
      progress: currentProgress,
      videoType: VideoType.ugc,
    );
  }

  void _setError(String error) {
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  String _escapeAudioUrl(String audioUrl) {
    return Platform.isWindows
        ? audioUrl.replaceAll(';', r'\;')
        : audioUrl.replaceAll(':', r'\:');
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) return;
    if (_playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (controller == null)
            NetworkImgLayer(
              src: widget.cover,
              quality: 100,
              width: widget.width,
              height: widget.height,
              borderRadius: BorderRadius.zero,
            )
          else
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: SimpleVideo(controller: controller),
            ),
          if (_loading) const CircularProgressIndicator(),
          if (_error case final error?)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withValues(alpha: 0.55),
              child: Text(
                error,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (widget.canPlay)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
        ],
      ),
    );
  }
}
