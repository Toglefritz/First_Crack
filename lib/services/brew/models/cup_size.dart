part of 'brew_profile.dart';

/// Represents common drink sizes used when preparing espresso beverages.
///
/// These values help determine target output volume, water dosing,
/// and recommended brew ratios. Sizes are approximate and may vary
/// slightly between machines or drink types.
enum CupSize {
  /// Extra small drink size, typically used for ristretto shots
  /// or very short extractions. Approx. 20–25 ml.
  xs,

  /// Small drink size suitable for standard espresso shots.
  /// Approx. 25–35 ml.
  small,

  /// Medium drink size commonly used for lungo shots or
  /// milk-based beverages that include a single espresso shot.
  /// Approx. 40–60 ml.
  medium,

  /// Large drink size used for long drinks or larger milk beverages
  /// such as lattes or flat whites. Approx. 150–240 ml.
  large,

  /// Extra large size intended for oversized drinks or multi-shot
  /// beverages. Typically 240 ml and above.
  xl,
}