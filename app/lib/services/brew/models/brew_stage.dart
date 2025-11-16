import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// Represents the sequential stages of the espresso brewing process.
///
/// The brew stage tracks the current phase of coffee preparation, from initial heating through final extraction. Each
/// stage represents a distinct phase in the brewing workflow and can be compared using standard comparison operators to
/// determine progression through the brew cycle.
enum BrewStage {
  /// Initial stage where the espresso machine heats water to the target brewing temperature.
  ///
  /// During this stage, the machine's boiler brings water to the optimal extraction temperature (typically 190-205°F).
  /// This is the first stage of any brew cycle and ensures proper thermal stability before extraction begins.
  heating,

  /// Stage where coffee beans are ground to the appropriate particle size for espresso extraction.
  ///
  /// The grinding stage prepares fresh coffee grounds with the correct fineness for espresso brewing. Proper grinding
  /// is critical for achieving the right extraction rate and flavor profile.
  grinding,

  /// Pre-infusion stage where coffee grounds are gently saturated with water at low pressure.
  ///
  /// During pre-infusion, water is introduced to the coffee puck at reduced pressure (typically 2 bar) to evenly wet
  /// the grounds and allow them to bloom. This stage typically lasts 1-10 seconds and helps achieve more uniform
  /// extraction and reduce channeling.
  preInfusion,

  /// Main extraction stage where pressurized water is forced through the coffee grounds.
  ///
  /// The brewing stage is the primary extraction phase where water at full pressure (typically 9 bar) flows through the
  /// coffee puck to produce espresso. This stage continues until the target yield is reached or the shot time elapses,
  /// typically lasting 25-35 seconds total.
  brewing,

  /// Final stage indicating the brew cycle has finished and espresso is ready.
  ///
  /// The complete stage signifies that extraction has ended and the espresso shot has been fully pulled. At this point,
  /// the target yield has been achieved or the brew was manually stopped.
  complete;

  /// Creates a [BrewStage] from a string value.
  ///
  /// Returns [heating] if the string doesn't match any known stage.
  factory BrewStage.fromString(String value) {
    return values.firstWhere(
      (stage) => stage.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BrewStage.heating,
    );
  }

  /// Returns identifier for the [BrewStage] displayed in the UI.
  ///
  /// Note: This is a non-localized identifier. For localized labels, use the extension method `localizedLabel(context)`
  /// at the UI layer.
  String get label {
    return name;
  }

  /// Returns an file path to an image associated with each [BrewStage].
  String image() {
    // The base path for each image file.
    const String basePath = 'assets/images';

    switch (this) {
      case BrewStage.heating:
        return '$basePath/heating.png';
      case BrewStage.grinding:
        return '$basePath/grinding.png';
      case BrewStage.preInfusion:
        return '$basePath/pre_infusion.png';
      case BrewStage.brewing:
        return '$basePath/brewing.png';
      case BrewStage.complete:
        return '$basePath/brew_complete.png';
    }
  }
}

/// Extensions on the [BrewStage] enum.
extension BrewStageX on BrewStage {
  /// Returns the localized label for this brew stage.
  ///
  /// This should be used in UI code where BuildContext is available. For service/business logic, use the non-localized
  /// `label` getter instead.
  String localizedLabel(BuildContext context) {
    switch (this) {
      case BrewStage.heating:
        return context.l10n.heating;
      case BrewStage.grinding:
        return context.l10n.grinding;
      case BrewStage.preInfusion:
        return context.l10n.preInfusion;
      case BrewStage.brewing:
        return context.l10n.brewing;
      case BrewStage.complete:
        return context.l10n.complete;
    }
  }

  /// Determines if this brew stage is "less than" the provided stage in terms of occurring before it in the brew
  /// process.
  bool operator <(BrewStage other) {
    return index < other.index;
  }

  /// Determines if this brew stage is "less than or equal to" the provided stage in terms of occurring before or at the
  /// same point in the brew process.
  bool operator <=(BrewStage other) {
    return index <= other.index;
  }

  /// Determines if this brew stage is "greater than" the provided stage in terms of occurring after it in the brew
  /// process.
  bool operator >(BrewStage other) {
    return index > other.index;
  }

  /// Determines if this brew stage is "greater than or equal to" the provided stage in terms of occurring after or at
  /// the same point in the brew process.
  bool operator >=(BrewStage other) {
    return index >= other.index;
  }
}
