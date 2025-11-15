part of 'brew_profile.dart';

/// Describes how the espresso machine determines when to automatically end the extraction process.
///
/// Different modes allow the brewing system to stop based on time, output weight, flow characteristics, or pressure
/// behavior. These options enable both traditional and advanced automation styles depending on the user's preference.
enum AutoStopMode {
  /// Stops the extraction once the shot has reached a predefined duration.
  ///
  /// This is the most traditional auto-stop method and is often used for classic espresso recipes where consistency in
  /// total brew time is desired.
  byTime,
  /// Stops the extraction once the espresso output reaches a target weight.
  ///
  /// This method provides highly consistent brew ratios (e.g., 1:2), improving repeatability across different beans and
  /// grind settings.
  byYield,
  /// Ends the shot when the machine detects a specific flow rate threshold, such as a slowdown that indicates the puck
  /// is fully extracted.
  ///
  /// This method automatically adapts to grind size and puck resistance, making it useful for machines with real-time
  /// flow sensors.
  byFlowRate,
  /// Stops the extraction when a significant pressure decline is detected, signaling the end of optimal extraction.
  ///
  /// This profile mimics the behavior of lever machines and is especially useful for lighter roasts or advanced
  /// pressure-profiled shots.
  byPressureDrop,
}
