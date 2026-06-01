import 'dart:io';

import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/services.dart' show PlatformException;

abstract final class BluetoothAudioDelay {
  static const int defaultCompensationMs = 180;
  static const int maxCompensationMs = 400;

  static int clampCompensationMs(int value) =>
      value.clamp(0, maxCompensationMs).toInt();

  static String? optionValue({
    required bool isBluetoothAudioOutput,
    required bool enabled,
    required int compensationMs,
  }) {
    final ms = clampCompensationMs(compensationMs);
    if (!isBluetoothAudioOutput || !enabled || ms == 0) {
      return null;
    }
    return (-(ms / 1000)).toStringAsFixed(3);
  }

  static Future<String?> queryOptionValue({
    required bool enabled,
    required int compensationMs,
  }) async {
    if (!Platform.isAndroid || !enabled) {
      return null;
    }
    try {
      final isBluetooth = await Utils.channel.invokeMethod<bool>(
            'isBluetoothAudioOutput',
          ) ??
          false;
      return optionValue(
        isBluetoothAudioOutput: isBluetooth,
        enabled: enabled,
        compensationMs: compensationMs,
      );
    } on PlatformException {
      return null;
    }
  }
}
