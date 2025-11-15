part of 'brew_profile.dart';

/// Represents the type of espresso-based drink being prepared.
///
/// Each variant corresponds to a traditional espresso style with different brew volumes, strengths, and taste profiles.
/// These values help determine machine behavior such as water output, ratio targets, and recommended brewing
/// parameters.
enum CoffeeType {
  /// A standard espresso shot, typically brewed at a 1:2 ratio (e.g., 18g in → 36g out). Produces a balanced,
  /// full-bodied extraction and serves as the foundation for most espresso-based drinks.
  espresso,
  /// A shorter, more concentrated shot brewed at a tighter ratio (typically around 1:1 to 1:1.5). Ristretto shots
  /// emphasize sweetness, syrupy texture, and reduced bitterness compared to a traditional espresso.
  ristretto,
  /// A longer extraction produced at a higher ratio (typically 1:3 or greater). Lungo shots have a lighter body,
  /// increased extraction, and a more aromatic but less intense flavor profile.
  lungo,
  /// A diluted espresso drink created by adding hot water after brewing. Typically made using a standard espresso shot
  /// combined with 1–2 parts water. Results in a beverage similar in strength to drip coffee but with espresso
  /// character.
  americano,
}
