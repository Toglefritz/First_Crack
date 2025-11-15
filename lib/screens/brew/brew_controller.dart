import 'package:flutter/material.dart';

import '../../services/brew/brew_service.dart';
import '../../services/brew/models/brew_stage.dart';
import 'brew_route.dart';
import 'brew_view.dart';

/// Controller for the [BrewRoute].
///
/// Extends State<BrewRoute> to provide state management capabilities and serves as the bridge between the route and
/// view components. Manages the brewing process and communicates with the BrewService.
class BrewController extends State<BrewRoute> {
  late final BrewService _brewService;

  @override
  void initState() {
    super.initState();
    _brewService = BrewService()
      ..addListener(_onBrewUpdate)
      ..updateProfile(widget.brewingProfile)
      ..startBrew();
  }

  @override
  void dispose() {
    _brewService
      ..removeListener(_onBrewUpdate)
      ..dispose();

    super.dispose();
  }

  /// Called when the brew service updates its state.
  void _onBrewUpdate() {
    setState(() {});
  }

  /// Gets the current brew service instance.
  BrewService get brewService => _brewService;

  /// Handles stopping the brew early.
  void onStopBrew() {
    _brewService.stopBrew();
  }

  /// Handles navigation back to the home screen.
  void onBack() {
    Navigator.of(context).pop();
  }

  /// Gets the current brew stage.
  BrewStage get brewStage => _brewService.brewStage;

  /// Gets the estimated time remaining in seconds.
  double get timeRemaining {
    final double targetTime = _brewService.profile.shotTimeSeconds;
    final double elapsed = _brewService.elapsedSeconds;
    return (targetTime - elapsed).clamp(0.0, targetTime);
  }

  /// Cancels a brew.
  void cancelBrew() {
    _brewService.stopBrew();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => BrewView(this);
}
