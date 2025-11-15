/// Represents common preset espresso output yields in grams.
///
/// These presets define typical extraction yields that, when combined with a dose preset, determine the brew ratio.
/// Standard espresso ratios range from 1:1 (ristretto) to 1:3 (lungo), with 1:2 being the classic espresso ratio.
enum OutputPreset {
  /// A very short, concentrated extraction (ristretto style). Approx. 18 grams output.
  /// With an 18g dose, this produces a 1:1 ratio.
  ristretto(18),

  /// A short, intense extraction. Approx. 27 grams output.
  /// With an 18g dose, this produces a 1:1.5 ratio.
  short(27),

  /// A classic, balanced espresso extraction. Approx. 36 grams output.
  /// With an 18g dose, this produces the standard 1:2 ratio.
  standard(36),

  /// A longer, more diluted extraction. Approx. 45 grams output.
  /// With an 18g dose, this produces a 1:2.5 ratio.
  long(45),

  /// A very long extraction (lungo style). Approx. 54 grams output.
  /// With an 18g dose, this produces a 1:3 ratio.
  lungo(54);

  /// The espresso output yield in grams.
  final double output;

  /// Creates an instance of [OutputPreset].
  const OutputPreset(this.output);
}
