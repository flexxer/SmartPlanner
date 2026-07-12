import 'package:flutter/material.dart';

/// Normalizes stored [Category.colorValue] to a Flutter [Color].
Color categoryColorFromValue(int colorValue) {
  if (colorValue > 0xFFFFFF) {
    return Color(colorValue);
  }
  return Color(0xFF000000 | colorValue);
}
