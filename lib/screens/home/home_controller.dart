import 'package:flutter/material.dart';

import '../../services/brew/models/brew_ratio.dart';
import 'home_route.dart';
import 'home_view.dart';
import 'models/dose_preset.dart';
import 'models/output_preset.dart';

/// Controller for the [HomeRoute].
///
/// Extends State<HomeRoute> to provide state management capabilities and serves as the bridge between the route and
/// view components. All user interactions and state changes are handled here.
class HomeController extends State<HomeRoute> {
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
  void onConfirm() {
    // TODO start the brew and navigate to the screen for monitoring the brew
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
