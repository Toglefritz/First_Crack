/// Root application widget for the first_crack Flutter application.
/// 
/// This file contains the main application widget that configures the Flutter app
/// with Material Design theming and sets up the initial route to the home screen
/// following MVC architecture patterns.
library;

import 'l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'screens/home/home_route.dart';

part 'theme/app_theme.dart';

/// Root application widget that configures the Flutter app.
/// 
/// This widget serves as the top-level container for the entire application
/// and is responsible for:
/// * Setting up the Material Design theme and color scheme
/// * Configuring the app title and debug settings
/// * Defining the initial route (home screen)
/// * Enabling Material 3 design system
/// 
/// The widget follows the StatelessWidget pattern as it contains no mutable state and serves purely as a configuration 
/// container.
class FirstCrack extends StatelessWidget {
  /// Creates the root application widget.
  const FirstCrack({super.key});

  /// Builds the widget tree for the root application.
  /// 
  /// Returns a [MaterialApp] configured with:
  /// * App title derived from the project name
  /// * Light and dark themes from [AppTheme]
  /// * Home route pointing to the main screen
  /// * Debug banner disabled for cleaner presentation
  /// * Localization support for multiple languages
  /// 
  /// The [MaterialApp] provides the foundation for Material Design components and navigation throughout the 
  /// application. Theme switching is handled automatically based on system preferences.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Crack',
      debugShowCheckedModeBanner: false,

      // Themes with accessibility support
      theme: _AppTheme.lightTheme,
      darkTheme: _AppTheme.darkTheme,
      home: const HomeRoute(),

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}