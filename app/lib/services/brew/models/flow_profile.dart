part of 'brew_profile.dart';

/// Represents predefined water flow profiles.
enum FlowProfile {
  /// A gentle initial flow that gradually increases to full extraction.
  ///
  /// This profile wets the puck slowly, helping reduce channeling and providing a smooth transition into high-pressure
  /// extraction. It is commonly used for medium-dark roasts or when aiming for a rounded, less aggressive flavor
  /// profile.
  softRamp,

  /// A short, low-pressure bloom phase followed by a hold period before transitioning into full pressure.
  ///
  /// This profile is designed to allow trapped gases in the coffee puck to release before the main extraction begins.
  /// It improves consistency, helps prevent channeling, and enhances clarity in lighter roasts.
  bloomAndHold,

  /// Begins with full extraction pressure and gradually reduces pressure throughout the shot.
  ///
  /// This profile mimics advanced lever machines and is commonly used for lighter roasts to improve sweetness and
  /// balance. The decreasing pressure reduces astringency in the later stages of extraction.
  decliningPressure,
}
