part of '../app.dart';

/// Provides theme configuration for the application.
class _AppTheme {
  /// The primary seed color used for generating the color scheme.
  ///
  /// This rich gold color evokes the warm, inviting tones of espresso crema and serves as the foundation for both light
  /// and dark themes, with Material 3 automatically generating complementary colors for various UI elements.
  static final Color _seedColor = Colors.amber[700]!;

  /// Light theme configuration for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }

  /// Dark theme configuration for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        surfaceTint: const Color(0xFF212121),
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }
}
