import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Provides a convenient way to access the app's localized strings.
///
/// Instead of writing `AppLocalizations.of(context)!`, this extension allows the app to simply use `context.l10n`.
extension AppLocalizationsX on BuildContext {
  /// Returns the `AppLocalizations` instance for the current `BuildContext`.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
