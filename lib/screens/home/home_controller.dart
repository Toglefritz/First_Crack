import 'package:flutter/material.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen that manages state and business logic.
///
/// Extends State<HomeRoute> to provide state management capabilities and serves as the bridge between the route and
/// view components. All user interactions and state changes are handled here.
class HomeController extends State<HomeRoute> {
  /// Current state of the lamp (on/off).
  ///
  /// This demonstrates basic state management within the controller. The lamp state is toggled when the user interacts
  /// with the switch.
  bool _isLampOn = false;

  /// Toggles the lamp state and triggers a UI rebuild.
  ///
  /// This method demonstrates how user interactions are handled in the controller layer, with setState() triggering
  /// view updates.
  void toggleLamp(bool value) {
    setState(() {
      _isLampOn = value;
    });
  }

  /// Getter for the current lamp state.
  ///
  /// Provides read-only access to the lamp state for the view layer.
  bool get isLampOn => _isLampOn;

  @override
  Widget build(BuildContext context) => HomeView(this);
}
