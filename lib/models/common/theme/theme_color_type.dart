import 'package:flutter/material.dart';

const amberThemeColor = Colors.amber;

const List<({Color color, String label})> colorThemeTypes = [
  (color: amberThemeColor, label: '琥珀色'),
];

Color resolveThemeColor(int storedValue) {
  if (storedValue >= 0x01000000) {
    return Color(storedValue);
  }
  return amberThemeColor;
}

String formatThemeColorHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}';
