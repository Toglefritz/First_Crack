/// Represents common preset coffee doses used when preparing espresso.
///
/// These presets fall within the typical usable range of 16–22 grams. Each value corresponds to a dose amount
/// frequently used for different espresso strengths, basket sizes, and roast styles.
enum DosePreset {
  /// A lighter dose commonly used for smaller baskets or softer, more acidic extractions. Approx. 16 grams.
  light(16),

  /// A balanced, versatile dose used for most standard espresso preparations. Approx. 18 grams.
  standard(18),

  /// A slightly heavier dose used for increased body and intensity, often paired with medium or dark roasts. Approx. 20
  /// grams.
  strong(20),

  /// A high-end, heavy dose used for baskets designed for large extractions or turbo-style shots. Approx. 22 grams.
  extraStrong(22);

  /// The coffee does in grams.
  final double dose;

  /// Creates an instance of [DosePreset].
  const DosePreset(this.dose);
}
