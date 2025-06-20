// plastic_factory_management/lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  /// Main brand color used across the app (gradient start).
  static const Color primary = Color(0xFFDE6D4D);

  /// Secondary brand color used for gradients and dark elements.
  static const Color dark = Color(0xFF848484);

  /// Secondary color used for highlights and accents.
  static const Color secondary = Color(0xFF2196F3);

  /// Accent orange color used for pending statuses.
  static const Color accentOrange = Color(0xFFFFA726);

  /// Convenient list of gradient colors following the brand scheme.
  static const List<Color> gradient = [primary, dark];

  // Newly added color
  static const Color lightGrey = Color(0xFFF5F5F5);

  static MaterialColor get primarySwatch => _createMaterialColor(primary);

  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}