import 'package:flutter/material.dart';
import '../../services/brew/models/brew_profile.dart';
import 'brew_controller.dart';

/// The brew monitoring route for the application.
///
/// This screen displays the progress of an active brew and allows the user to monitor and control the brewing process.
class BrewRoute extends StatefulWidget {
  /// Creates the brew route widget.
  const BrewRoute({
    required this.brewingProfile,
    required this.fcmToken,
    super.key,
  });

  /// An object representing the brewing profile which contains information about the brew.
  final BrewingProfile brewingProfile;

  /// The FCM device token for receiving push notifications.
  ///
  /// This token is required to start the cloud brew simulation, as it identifies the device that should receive the
  /// brew stage notifications.
  final String? fcmToken;

  @override
  State<BrewRoute> createState() => BrewController();
}
