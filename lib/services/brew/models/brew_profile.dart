/// A configuration model describing all parameters used when preparing an espresso-based drink.
library;

part 'flow_profile.dart';
part 'pressure_profile.dart';
part 'auto_stop_mode.dart';
part 'cup_size.dart';
part 'coffee_type.dart';

/// A configuration model describing all parameters used when preparing an espresso-based drink.
///
/// This model includes both essential espresso controls (dose, yield, brew ratio, temperature, pre-infusion, etc.) as
/// well as advanced pressure/flow profiling and milk/steam settings for more complex drinks.
///
/// The default values represent the most typical settings used for standard espresso preparation.
class BrewingProfile {
  // MARK: Core Espresso Brewing Controls

  /// The amount of ground coffee used in grams. Typical range: 16–22g. Default is 18g.
  final double doseGrams;

  /// The final espresso output weight in grams. Default yield: 36g (~1:2 ratio with an 18g dose).
  final double yieldGrams;

  /// Brew ratio expressed as a multiplier (e.g., 2.0 = 1:2 ratio). Typical espresso ratio: 1:2.0.
  final double brewRatio;

  /// Brew water temperature in Fahrenheit. Typical espresso brewing temperature: 190–205°F.
  final double waterTemperatureF;

  /// The duration of pre-infusion in seconds. Typical range: 1–10 seconds. Default is 3 seconds.
  final double preInfusionSeconds;

  /// The pre-infusion pressure in bars. Typical low-pressure pre-wet: 2 bar.
  final double preInfusionPressureBar;

  // MARK: Pressure and Flow Profile Controls

  /// The main extraction pressure in bars. Standard espresso: ~9 bars.
  final double pumpPressureBar;

  /// A simple descriptor for the flow profile to use. e.g., soft ramp, bloom & hold, declining pressure.
  final FlowProfile flowProfile;

  /// A preset describing how pressure changes during extraction.
  final PressureProfile pressureProfile;

  // MARK: Shot Timing Controls

  /// Total planned shot time in seconds. Standard: 25–35 seconds. Default: 30 seconds.
  final double shotTimeSeconds;

  /// Determines how the shot should automatically end.
  final AutoStopMode autoStopMode;

  // MARK: Milk and Steam Controls

  /// Target milk temperature in Fahrenheit. Typical range: 130–150°F. Default: 140°F.
  final double milkTemperatureF;

  /// Foam level from 0 (very wet foam) to 1.0 (very dry foam). Default: 0.5 (balanced).
  final double foamLevel;

  /// Ratio of coffee to milk (0 = all coffee, 1 = all milk). Default: 0.7 (latte-like).
  final double milkRatio;

  // MARK: Machine Controls

  /// Whether the user has initiated a brew cycle. Defaults to false.
  final bool startBrew;

  /// Machine warm-up level from 0–1.0 (0 = cold, 1 = ready). Default: 1.0 (machine is warmed up).
  final double warmUpLevel;

  /// Whether a cleaning cycle should run after this brew. Default: false.
  final bool cleaningCycle;

  /// Size of the cup being prepared.
  final CupSize cupSize;

  /// A general strength selector from 0–1.0. This may influence multiple parameters behind the scenes.
  final double strength;

  /// The type of coffee being prepared (espresso, lungo, etc.).
  final CoffeeType coffeeType;

  // MARK: Constructor

  /// Creates a brewing profile with sensible espresso defaults.
  const BrewingProfile({
    this.doseGrams = 18.0,
    this.yieldGrams = 36.0,
    this.brewRatio = 2.0,
    this.waterTemperatureF = 200.0,
    this.preInfusionSeconds = 3.0,
    this.preInfusionPressureBar = 2.0,
    this.pumpPressureBar = 9.0,
    this.flowProfile = FlowProfile.softRamp,
    this.pressureProfile = PressureProfile.classic9Bar,
    this.shotTimeSeconds = 30.0,
    this.autoStopMode = AutoStopMode.byYield,
    this.milkTemperatureF = 140.0,
    this.foamLevel = 0.5,
    this.milkRatio = 0.7,
    this.startBrew = false,
    this.warmUpLevel = 1.0,
    this.cleaningCycle = false,
    this.cupSize = CupSize.medium,
    this.strength = 0.5,
    this.coffeeType = CoffeeType.espresso,
  });

  /// Creates a copy of this profile with modified values.
  BrewingProfile copyWith({
    double? doseGrams,
    double? yieldGrams,
    double? brewRatio,
    double? waterTemperatureF,
    double? preInfusionSeconds,
    double? preInfusionPressureBar,
    double? pumpPressureBar,
    FlowProfile? flowProfile,
    PressureProfile? pressureProfile,
    double? shotTimeSeconds,
    AutoStopMode? autoStopMode,
    double? milkTemperatureF,
    double? foamLevel,
    double? milkRatio,
    bool? startBrew,
    double? warmUpLevel,
    bool? cleaningCycle,
    CupSize? cupSize,
    double? strength,
    CoffeeType? coffeeType,
  }) {
    return BrewingProfile(
      doseGrams: doseGrams ?? this.doseGrams,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      brewRatio: brewRatio ?? this.brewRatio,
      waterTemperatureF: waterTemperatureF ?? this.waterTemperatureF,
      preInfusionSeconds: preInfusionSeconds ?? this.preInfusionSeconds,
      preInfusionPressureBar:
          preInfusionPressureBar ?? this.preInfusionPressureBar,
      pumpPressureBar: pumpPressureBar ?? this.pumpPressureBar,
      flowProfile: flowProfile ?? this.flowProfile,
      pressureProfile: pressureProfile ?? this.pressureProfile,
      shotTimeSeconds: shotTimeSeconds ?? this.shotTimeSeconds,
      autoStopMode: autoStopMode ?? this.autoStopMode,
      milkTemperatureF: milkTemperatureF ?? this.milkTemperatureF,
      foamLevel: foamLevel ?? this.foamLevel,
      milkRatio: milkRatio ?? this.milkRatio,
      startBrew: startBrew ?? this.startBrew,
      warmUpLevel: warmUpLevel ?? this.warmUpLevel,
      cleaningCycle: cleaningCycle ?? this.cleaningCycle,
      cupSize: cupSize ?? this.cupSize,
      strength: strength ?? this.strength,
      coffeeType: coffeeType ?? this.coffeeType,
    );
  }
}
