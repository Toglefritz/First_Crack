part of 'brew_profile.dart';

/// Describes how water pressure changes throughout the espresso extraction.
///
/// Each profile represents a different pressure curve commonly used in both commercial and enthusiast espresso
/// machines. These curves influence flavor, extraction balance, clarity, and body.
enum PressureProfile {
  /// A traditional, constant-pressure profile that maintains ~9 bars throughout the entire extraction.
  ///
  /// This is the most common profile used on standard pump-driven espresso machines. It produces a balanced flavor and
  /// is suitable for most medium and dark roasts.
  classic9Bar,

  /// Begins with a short low-pressure bloom phase, then gradually increases to full pressure before tapering off near
  /// the end of the shot.
  ///
  /// This profile helps reduce channeling, improve clarity, and enhance sweetness—especially effective for
  /// light-roasted coffees.
  bloomAndDecline,

  /// A fast, high-flow, lower-pressure extraction designed to reduce shot time while maintaining clarity and sweetness.
  ///
  /// Popularized by modern espresso approaches, this profile produces a lighter-bodied but highly aromatic espresso
  /// with reduced bitterness.
  turboShot,
}
