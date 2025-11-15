import 'package:flutter/material.dart';

/// Provides a convenient way to access the app's theme.
///
/// Instead of writing `Theme.of(context)`, this extension allows the app to simply use `context.theme`. Similarly, to
/// access the app's color scheme, instead of writing `Theme.of(context).colorScheme`, this extension allows the app to
/// simply use `context.colorScheme`.
extension ThemeDataX on BuildContext {
  /// Returns the `ThemeData` instance for the current `BuildContext`.
  ThemeData get theme => Theme.of(this);

  /// Returns the `ColorScheme` instance for the current `BuildContext`.
  ColorScheme get colorScheme => theme.colorScheme;
}
