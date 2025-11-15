/// Represents the brew ratio calculated from dose and output values.
///
/// The brew ratio is expressed as a multiplier (e.g., 2.0 for a 1:2 ratio) and is calculated by dividing the output
/// yield by the input dose. This ratio is a key parameter in espresso extraction that affects strength, flavor
/// balance, and extraction efficiency.
class BrewRatio {
  /// The coffee dose in grams (input).
  final double dose;

  /// The espresso output yield in grams (output).
  final double output;

  /// Creates a brew ratio from the given dose and output values.
  const BrewRatio({
    required this.dose,
    required this.output,
  });

  /// Calculates the brew ratio as a multiplier (output / dose).
  ///
  /// For example:
  /// - 18g dose with 36g output = 2.0 (1:2 ratio)
  /// - 18g dose with 27g output = 1.5 (1:1.5 ratio)
  /// - 20g dose with 40g output = 2.0 (1:2 ratio)
  double get ratio => output / dose;

  /// Returns a formatted string representation of the brew ratio.
  ///
  /// Example: "1:2.0" for a standard espresso ratio.
  String get formatted => '1:${ratio.toStringAsFixed(1)}';

  @override
  String toString() => formatted;
}
