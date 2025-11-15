import 'package:flutter/foundation.dart';

import 'models/brew_profile.dart';

/// Service responsible for managing the espresso brewing process.
///
/// This service handles the configuration, execution, and monitoring of coffee brewing operations. It maintains the
/// current brewing profile and provides methods to start, stop, and modify brew parameters.
class BrewService extends ChangeNotifier {
  /// The current brewing profile configuration.
  BrewingProfile _profile = const BrewingProfile();

  /// Whether a brew is currently in progress.
  bool _isBrewing = false;

  /// Current brew progress from 0.0 to 1.0.
  double _brewProgress = 0.0;

  /// Elapsed time in seconds since brew started.
  double _elapsedSeconds = 0.0;

  /// Current extraction yield in grams.
  double _currentYieldGrams = 0.0;

  /// Gets the current brewing profile.
  BrewingProfile get profile => _profile;

  /// Gets whether a brew is currently in progress.
  bool get isBrewing => _isBrewing;

  /// Gets the current brew progress (0.0 to 1.0).
  double get brewProgress => _brewProgress;

  /// Gets the elapsed brew time in seconds.
  double get elapsedSeconds => _elapsedSeconds;

  /// Gets the current extraction yield in grams.
  double get currentYieldGrams => _currentYieldGrams;

  /// Updates the brewing profile with new parameters.
  ///
  /// This method allows partial updates using the profile's copyWith method.
  void updateProfile(BrewingProfile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  /// Starts the brewing process with the current profile.
  ///
  /// Returns true if brew started successfully, false if already brewing.
  bool startBrew() {
    if (_isBrewing) return false;

    _isBrewing = true;
    _brewProgress = 0.0;
    _elapsedSeconds = 0.0;
    _currentYieldGrams = 0.0;
    _profile = _profile.copyWith(startBrew: true);
    notifyListeners();

    // Simulates interaction with a coffee machine.
    _simulateBrew();

    return true;
  }

  /// Stops the current brewing process.
  void stopBrew() {
    if (!_isBrewing) return;

    _isBrewing = false;
    _profile = _profile.copyWith(startBrew: false);
    notifyListeners();
  }

  /// Simulates the brewing process for the imaginary coffee machine with which this service interacts.
  Future<void> _simulateBrew() async {
    final double targetTime = _profile.autoStopMode == AutoStopMode.byTime ? _profile.shotTimeSeconds : 30.0;
    final double targetYield = _profile.yieldGrams;

    while (_isBrewing && _brewProgress < 1.0) {
      await Future<void>.delayed(const Duration(milliseconds: 100));

      _elapsedSeconds += 0.1;

      // Update progress based on auto-stop mode
      if (_profile.autoStopMode == AutoStopMode.byTime) {
        _brewProgress = (_elapsedSeconds / targetTime).clamp(0.0, 1.0);
        _currentYieldGrams = targetYield * _brewProgress;
      } else {
        // Simulate yield-based progress
        _currentYieldGrams += targetYield / (targetTime * 10);
        _brewProgress = (_currentYieldGrams / targetYield).clamp(0.0, 1.0);
      }

      notifyListeners();

      // Auto-stop when complete
      if (_brewProgress >= 1.0) {
        stopBrew();
      }
    }
  }

  /// Resets the service to initial state.
  void reset() {
    _profile = const BrewingProfile();
    _isBrewing = false;
    _brewProgress = 0.0;
    _elapsedSeconds = 0.0;
    _currentYieldGrams = 0.0;
    notifyListeners();
  }

  /// Updates the dose amount in grams.
  void updateDose(double grams) {
    _profile = _profile.copyWith(doseGrams: grams);
    notifyListeners();
  }

  /// Updates the target yield in grams.
  void updateYield(double grams) {
    _profile = _profile.copyWith(yieldGrams: grams);
    notifyListeners();
  }

  /// Updates the water temperature in Fahrenheit.
  void updateTemperature(double temperatureF) {
    _profile = _profile.copyWith(waterTemperatureF: temperatureF);
    notifyListeners();
  }

  /// Updates the coffee type.
  void updateCoffeeType(CoffeeType type) {
    _profile = _profile.copyWith(coffeeType: type);
    notifyListeners();
  }

  /// Updates the cup size.
  void updateCupSize(CupSize size) {
    _profile = _profile.copyWith(cupSize: size);
    notifyListeners();
  }

  /// Updates the strength level (0.0 to 1.0).
  void updateStrength(double strength) {
    _profile = _profile.copyWith(strength: strength.clamp(0.0, 1.0));
    notifyListeners();
  }
}
