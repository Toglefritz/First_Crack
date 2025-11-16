part of '../push_notification_service.dart';

/// Enum representing the current stage of the brewing process.
///
/// These stages correspond to the notification stages sent by the First Crack Cloud Functions backend during a brew
/// simulation.
enum PNSBrewStage {
  /// Machine is heating water to the target temperature.
  heating('heating'),

  /// Machine is ready to begin brewing.
  ///
  /// This stage typically includes action buttons to start the brew or adjust parameters.
  ready('ready'),

  /// Pre-infusion has started.
  ///
  /// Pre-infusion is the initial low-pressure wetting of the coffee puck before full extraction begins.
  preinfusionStart('preinfusion_start'),

  /// Pre-infusion is complete and extraction is ramping up.
  preinfusionComplete('preinfusion_complete'),

  /// Extraction is in progress.
  ///
  /// This is the main brewing stage where espresso is being extracted at full pressure. May include live video or
  /// progress updates.
  extractionProgress('extraction_progress'),

  /// Extraction is complete and finishing up.
  extractionComplete('extraction_complete'),

  /// Brew is complete.
  ///
  /// This is the final stage, typically including a summary of the brew and a final image of the finished espresso.
  brewComplete('brew_complete');

  /// The string value used in FCM messages.
  final String value;

  /// Creates a brew stage with the given string value.
  const PNSBrewStage(this.value);

  /// Creates a [PNSBrewStage] from a string value.
  ///
  /// Returns [heating] if the string doesn't match any known stage.
  factory PNSBrewStage.fromString(String value) {
    switch (value) {
      case 'heating':
        return PNSBrewStage.heating;
      case 'ready':
        return PNSBrewStage.ready;
      case 'preinfusion_start':
        return PNSBrewStage.preinfusionStart;
      case 'preinfusion_complete':
        return PNSBrewStage.preinfusionComplete;
      case 'extraction_progress':
        return PNSBrewStage.extractionProgress;
      case 'extraction_complete':
        return PNSBrewStage.extractionComplete;
      case 'brew_complete':
        return PNSBrewStage.brewComplete;
      default:
        return PNSBrewStage.heating;
    }
  }

  /// Gets a human-readable display name for this stage.
  String get displayName {
    switch (this) {
      case PNSBrewStage.heating:
        return 'Heating';
      case PNSBrewStage.ready:
        return 'Ready';
      case PNSBrewStage.preinfusionStart:
        return 'Pre-infusion Started';
      case PNSBrewStage.preinfusionComplete:
        return 'Pre-infusion Complete';
      case PNSBrewStage.extractionProgress:
        return 'Extracting';
      case PNSBrewStage.extractionComplete:
        return 'Extraction Complete';
      case PNSBrewStage.brewComplete:
        return 'Complete';
    }
  }
}
