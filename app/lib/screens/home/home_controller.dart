import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/brew/models/brew_profile.dart';
import '../../services/brew/models/brew_ratio.dart';
import '../../services/push_notification/push_notification_service.dart';
import '../brew/brew_route.dart';
import 'home_route.dart';
import 'home_view.dart';
import 'models/dose_preset.dart';
import 'models/output_preset.dart';

/// Controller for the [HomeRoute].
///
/// Extends `State<HomeRoute>` to provide state management capabilities and serves as the bridge between the route and
/// view components. All user interactions and state changes are handled here.
class HomeController extends State<HomeRoute> {
  /// Push notification service instance for managing FCM and notifications.
  final PushNotificationService _pushNotificationService = PushNotificationService();

  /// The coffee dose selected on this screen, from a defined set of presets.
  DosePreset dosePreset = DosePreset.standard;

  /// The espresso output yield selected on this screen, from a defined set of presets.
  OutputPreset outputPreset = OutputPreset.standard;

  /// The brew temperature in Fahrenheit. Typical espresso range: 190–205°F.
  double temperatureF = 200.0;

  /// Calculates the current brew ratio based on selected dose and output presets.
  BrewRatio get brewRatio => BrewRatio(
        dose: dosePreset.dose,
        output: outputPreset.output,
      );

  @override
  void initState() {
    // Request push notification permissions
    unawaited(_requestPnsPermissions());

    super.initState();
  }

  /// Requests the permissions necessary for the delivery of push notifications from the user.
  ///
  /// This method initializes the push notification service and requests notification permissions from the user. On
  /// iOS/macOS, this displays the system permission dialog. On Android 13+, this requests the POST_NOTIFICATIONS
  /// permission. On older Android versions, permissions are granted automatically.
  ///
  /// The method handles the following scenarios:
  ///
  /// * Service initialization failure - Logs error and returns without requesting permissions
  /// * Permission granted - Logs success and FCM token
  /// * Permission denied - Logs denial (user can enable later in settings)
  /// * Permission not determined - Logs that user dismissed the dialog
  Future<void> _requestPnsPermissions() async {
    try {
      // Initialize the push notification service
      final bool initialized = await _pushNotificationService.initialize();

      if (!initialized) {
        debugPrint('Failed to initialize push notification service');
        return;
      }

      // Request notification permissions from the user
      final NotificationPermissionStatus status = await _pushNotificationService.requestPermission();

      // Handle the permission result
      switch (status) {
        case NotificationPermissionStatus.authorized:
          debugPrint('Notification permissions granted');
          debugPrint('FCM Token: ${_pushNotificationService.fcmToken}');
        case NotificationPermissionStatus.denied:
          debugPrint('Notification permissions denied');
        case NotificationPermissionStatus.notDetermined:
          debugPrint('Notification permissions not determined');
        case NotificationPermissionStatus.provisional:
          debugPrint('Provisional notification permissions granted');
      }
    } catch (error) {
      debugPrint('Requesting push notification permissions failed with exception, $error');
    }
  }

  /// Updates the coffee dose selected on this screen.
  void onDoseSelected(DosePreset dosePreset) {
    setState(() {
      this.dosePreset = dosePreset;
    });
  }

  /// Updates the espresso output yield selected on this screen.
  void onOutputSelected(OutputPreset outputPreset) {
    setState(() {
      this.outputPreset = outputPreset;
    });
  }

  /// Updates the brew temperature.
  void onTemperatureChanged(double temperature) {
    setState(() {
      temperatureF = temperature;
    });
  }

  /// Handles submission of the selected brew profile parameters to start a brew.
  Future<void> onConfirm() async {
    // Create a BrewingProfile object based on the user's selections.
    final BrewingProfile profile = BrewingProfile(
      doseGrams: dosePreset.dose,
      yieldGrams: outputPreset.output,
      waterTemperatureF: temperatureF,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BrewRoute(
          brewingProfile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
