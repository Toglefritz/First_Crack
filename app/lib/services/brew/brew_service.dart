import 'package:flutter/foundation.dart';

import 'models/brew_profile.dart';
import 'models/brew_stage.dart';

/// Service responsible for managing the espresso brewing process.
///
/// This service handles the configuration, execution, and monitoring of coffee brewing operations. It maintains the
/// current brewing profile and provides methods to start, stop, and modify brew parameters.
class BrewService extends ChangeNotifier {
  /// The current brewing profile configuration.
  BrewingProfile _profile = const BrewingProfile();

  /// Whether a brew is currently in progress.
  bool _isBrewing = false;

  /// Current brew stage. The brewing process always starts with heating the water.
  BrewStage _brewStage = BrewStage.heating;

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

  /// Gets the current brew stage.
  BrewStage get brewStage => _brewStage;

  /// Gets the current brew progress (0.0 to 1.0).
  double get brewProgress => _brewProgress;

  /// Gets the elapsed brew time in seconds.
  double get elapsedSeconds => _elapsedSeconds;

  /// Gets the current extraction yield in grams.
  double get currentYieldGrams => _currentYieldGrams;

  // MARK: Simulated Durations

  /// Simulated duration for the heating portion of the brew.
  final double heatingDuration = 30.0;

  /// Simulated duration for the pre-infusion portion of the brew.
  final double preInfusionDuration = 15.0;

  /// Simulated duration for the extraction portion of the brew.
  final double extractionDuration = 30.0;

  /// Total duration of the brewing process.
  double get totalDuration => heatingDuration + preInfusionDuration + extractionDuration; // 75 seconds

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
  Future<bool> startBrew() async {
    if (_isBrewing) return false;

    _isBrewing = true;
    _brewStage = BrewStage.heating;
    _brewProgress = 0.0;
    _elapsedSeconds = 0.0;
    _currentYieldGrams = 0.0;
    _profile = _profile.copyWith(startBrew: true);
    notifyListeners();

    // Simulates interaction with a coffee machine.
    await _simulateBrew();

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
    final double targetYield = _profile.yieldGrams;

    while (_isBrewing && _brewStage < BrewStage.complete) {
      await Future<void>.delayed(const Duration(milliseconds: 100));

      _elapsedSeconds += 0.1;

      // Update brew stage based on elapsed time
      if (_elapsedSeconds < heatingDuration) {
        _brewStage = BrewStage.heating;
      } else if (_elapsedSeconds < heatingDuration + preInfusionDuration) {
        _brewStage = BrewStage.preInfusion;
      } else if (_elapsedSeconds < totalDuration) {
        _brewStage = BrewStage.brewing;
        // Simulate yield during extraction phase
        final double extractionProgress =
            (_elapsedSeconds - heatingDuration - preInfusionDuration) / extractionDuration;
        _currentYieldGrams = targetYield * extractionProgress.clamp(0.0, 1.0);
      } else {
        _brewStage = BrewStage.complete;
        _currentYieldGrams = targetYield;
      }

      // Overall progress
      _brewProgress = (_elapsedSeconds / totalDuration).clamp(0.0, 1.0);

      notifyListeners();

      // Auto-stop when complete
      if (_elapsedSeconds >= totalDuration) {
        _brewStage = BrewStage.complete;
        stopBrew();
      }
    }
  }

  /// Resets the service to initial state.
  void reset() {
    _profile = const BrewingProfile();
    _isBrewing = false;
    _brewStage = BrewStage.heating;
    _brewProgress = 0.0;
    _elapsedSeconds = 0.0;
    _currentYieldGrams = 0.0;
    notifyListeners();
  }
}
