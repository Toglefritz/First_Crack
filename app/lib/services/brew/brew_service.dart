import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'models/brew_profile.dart';
import 'models/brew_stage.dart';

/// Service responsible for managing the espresso brewing process.
///
/// This service handles the configuration, execution, and monitoring of coffee brewing operations. It maintains the
/// current brewing profile and provides methods to start, stop, and modify brew parameters.
///
/// The service integrates with the First Crack Cloud Functions backend to trigger brew simulations that send push
/// notifications for each stage of the brewing process. The cloud backend handles:
/// - Scheduling notifications for each brew stage (heating, grinding, pre-infusion, brewing, complete)
/// - Enriching notifications with brew parameters and media
/// - Delivering notifications via Firebase Cloud Messaging (FCM)
///
/// The local service maintains brew state and progress for UI updates while the cloud backend manages the notification
/// delivery timeline.
class BrewService extends ChangeNotifier {
  /// HTTP client for making API requests to the cloud backend.
  final Client _httpClient;

  /// FCM device token for receiving push notifications.
  ///
  /// This token is required to start a brew simulation as it identifies the device that should receive the brew stage
  /// notifications.
  String? _fcmToken;

  /// Cloud Functions base URL.
  ///
  /// In production, this should be configured via environment variables or a configuration service. For development,
  /// this points to the deployed Cloud Functions.
  static const String _cloudFunctionsBaseUrl = 'https://us-central1-first-crack-demo.cloudfunctions.net';

  /// Creates a new BrewService instance.
  ///
  /// Parameters:
  /// - [httpClient]: Optional HTTP client for making API requests. If not provided,
  /// a default client is created. Providing a custom client is useful for testing.
  BrewService({Client? httpClient}) : _httpClient = httpClient ?? Client();

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

  /// Sets the FCM device token for receiving push notifications.
  ///
  /// This token must be set before starting a brew, as it is required by the cloud backend to send notifications to the
  /// correct device.
  ///
  /// The token is typically obtained from the PushNotificationService after initialization and permission grant.
  void setFcmToken(String? token) {
    _fcmToken = token;
    notifyListeners();
  }

  /// Gets the current FCM device token.
  String? get fcmToken => _fcmToken;

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
  /// This method initiates a brew simulation by:
  ///
  /// 1. Validating that an FCM token is available
  /// 2. Calling the cloud backend to start the notification sequence
  /// 3. Running a local simulation for UI progress updates
  ///
  /// The cloud backend handles sending push notifications for each brew stage, while the local simulation updates the
  /// UI with progress and parameters.
  ///
  /// Returns true if brew started successfully, false if already brewing or if the FCM token is not available.
  ///
  /// Throws an exception if the cloud API call fails.
  Future<bool> startBrew() async {
    if (_isBrewing) {
      debugPrint('BrewService: Brew already in progress');
      return false;
    }

    // Validate FCM token is available
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      debugPrint('BrewService: Cannot start brew - FCM token not available');

      return false;
    }

    _isBrewing = true;
    _brewStage = BrewStage.heating;
    _brewProgress = 0.0;
    _elapsedSeconds = 0.0;
    _currentYieldGrams = 0.0;
    _profile = _profile.copyWith(startBrew: true);
    notifyListeners();

    try {
      // Call cloud backend to start notification sequence
      await _startCloudBrewSimulation();

      // Run local simulation for UI updates
      await _simulateBrew();

      return true;
    } catch (error) {
      debugPrint('BrewService: Failed to start brew - $error');
      // Reset state on error
      _isBrewing = false;
      _profile = _profile.copyWith(startBrew: false);
      notifyListeners();
      rethrow;
    }
  }

  /// Stops the current brewing process.
  void stopBrew() {
    if (!_isBrewing) return;

    _isBrewing = false;
    _profile = _profile.copyWith(startBrew: false);
    notifyListeners();
  }

  /// Calls the cloud backend to start the brew notification sequence.
  ///
  /// This method sends a POST request to the Cloud Functions /startBrew endpoint with the current brew profile and FCM
  /// token. The backend will then schedule and send push notifications for each brew stage.
  ///
  /// Request payload:
  /// ```json
  /// {
  /// "deviceToken": "fcm_token_here",
  /// "brewType": "espresso",
  /// "dose": 18,
  /// "targetTemp": 93,
  /// "targetPressure": 9
  /// }
  /// ```
  ///
  /// Throws an exception if the API call fails or returns an error response.
  Future<void> _startCloudBrewSimulation() async {
    final Uri endpoint = Uri.parse('$_cloudFunctionsBaseUrl/startBrew');

    // Construct request payload from current profile
    // Convert Fahrenheit to Celsius for the API (cloud expects Celsius)
    final int temperatureCelsius = ((_profile.waterTemperatureF - 32) * 5 / 9).round();

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'deviceToken': _fcmToken,
      'brewType': 'espresso', // Currently hardcoded, could be added to profile
      'dose': _profile.doseGrams.toInt(),
      'targetTemp': temperatureCelsius,
      'targetPressure': _profile.pumpPressureBar.toInt(),
    };

    debugPrint('BrewService: Calling cloud endpoint to start brew simulation');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Payload: ${jsonEncode(requestBody)}');

    try {
      final Response response = await _httpClient.post(
        endpoint,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('BrewService: Cloud API response status: ${response.statusCode}');
      debugPrint('BrewService: Cloud API response body: ${response.body}');

      if (response.statusCode != 200) {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          'Cloud API error: ${errorData['error'] ?? 'Unknown error'} '
          '(${errorData['details'] ?? ''})',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception(
          'Cloud API returned success=false: ${responseData['error'] ?? 'Unknown error'}',
        );
      }

      debugPrint('BrewService: Cloud brew simulation started successfully');
      debugPrint('Brew ID: ${responseData['brewId']}');
    } catch (error) {
      debugPrint('BrewService: Failed to call cloud endpoint - $error');
      rethrow;
    }
  }

  /// Simulates the brewing process locally for UI updates.
  ///
  /// This method runs in parallel with the cloud notification sequence to provide real-time UI updates for brew
  /// progress, stage transitions, and parameter changes.
  ///
  /// The local simulation matches the timing of the cloud notifications:
  /// - Heating: 0-30s
  /// - Grinding: 30s (instant notification, but part of pre-infusion duration)
  /// - Pre-infusion: 30-45s
  /// - Brewing: 45-75s
  /// - Complete: 75s
  ///
  /// While the cloud backend sends push notifications at specific stages, this local simulation provides smooth
  /// progress updates for the UI at 100ms intervals.
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

  /// Disposes of the service and cleans up resources.
  ///
  /// Closes the HTTP client to free up resources. Call this when the service is no longer needed.
  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
