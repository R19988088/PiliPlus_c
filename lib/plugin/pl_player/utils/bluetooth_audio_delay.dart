import 'dart:io';

import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/services.dart' show PlatformException;

enum BluetoothAudioDelayOutputType {
  none,
  a2dp,
  ble,
  sco;

  static BluetoothAudioDelayOutputType fromValue(Object? value) {
    return switch (value) {
      'a2dp' => a2dp,
      'ble' => ble,
      'sco' => sco,
      _ => none,
    };
  }
}

abstract final class BluetoothAudioDelay {
  static const int defaultCompensationMs = 320;
  static const int maxCompensationMs = 400;

  static int clampCompensationMs(int value) =>
      value.clamp(0, maxCompensationMs).toInt();

  static int automaticCompensationMs(BluetoothAudioDelayOutputType type) {
    return switch (type) {
      BluetoothAudioDelayOutputType.a2dp => 300,
      BluetoothAudioDelayOutputType.ble => 180,
      BluetoothAudioDelayOutputType.sco => 120,
      BluetoothAudioDelayOutputType.none => 0,
    };
  }

  static String? optionValue({
    required BluetoothAudioDelayOutputType audioOutputType,
    required bool enabled,
    required int? compensationMs,
  }) {
    if (!enabled || audioOutputType == BluetoothAudioDelayOutputType.none) {
      return null;
    }
    final ms = compensationMs == null
        ? automaticCompensationMs(audioOutputType)
        : clampCompensationMs(compensationMs);
    if (ms == 0) {
      return null;
    }
    return (ms / 1000).toStringAsFixed(3);
  }

  static Future<String?> queryOptionValue({
    required bool enabled,
    required int? compensationMs,
  }) async {
    if (!Platform.isAndroid || !enabled) {
      return null;
    }
    try {
      final audioOutputType = BluetoothAudioDelayOutputType.fromValue(
        await Utils.channel.invokeMethod<String>('bluetoothAudioOutputType'),
      );
      return optionValue(
        audioOutputType: audioOutputType,
        enabled: enabled,
        compensationMs: compensationMs,
      );
    } on PlatformException {
      return null;
    }
  }
}
