import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/insets.dart';
import '../../theme/theme.dart';
import 'home_controller.dart';
import 'models/dose_preset.dart';
import 'models/output_preset.dart';

/// View widget for the home screen that handles UI presentation.
///
/// This StatelessWidget receives the controller as a parameter and uses it to access state and trigger actions. The
/// view contains no business logic and is purely declarative.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance that manages state and business logic.
  ///
  /// Used to access the current lamp state and trigger toggle actions.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background image filling the screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/coffee_machine_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // App title in upper-left corner
          Positioned(
            top: Insets.xSmall,
            left: Insets.small,
            child: SafeArea(
              child: Text(
                context.l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.inverseSurface,
                    ),
              ),
            ),
          ),

          // Left-side dose selector
          Positioned(
            left: Insets.medium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.dose,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                ...List.generate(
                  DosePreset.values.length,
                  (int index) {
                    final DosePreset preset = DosePreset.values[index];
                    final bool isSelected = preset == state.dosePreset;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xSmall),
                      child: OutlinedButton(
                        onPressed: () => state.onDoseSelected(preset),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              isSelected ? context.colorScheme.inversePrimary : context.colorScheme.surface,
                          foregroundColor:
                              isSelected ? context.colorScheme.primary : Theme.of(context).primaryColorDark,
                        ),
                        child: Text(
                          '${preset.dose.toInt()}g',
                          style: TextStyle(
                            color:
                                isSelected ? context.colorScheme.inverseSurface : Theme.of(context).primaryColorLight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Right-side output selector
          Positioned(
            right: Insets.medium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.output,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                ...List.generate(
                  OutputPreset.values.length,
                  (int index) {
                    final OutputPreset preset = OutputPreset.values[index];
                    final bool isSelected = preset == state.outputPreset;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xxSmall),
                      child: OutlinedButton(
                        onPressed: () => state.onOutputSelected(preset),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              isSelected ? context.colorScheme.inversePrimary : context.colorScheme.surface,
                          foregroundColor:
                              isSelected ? context.colorScheme.primary : Theme.of(context).primaryColorDark,
                        ),
                        child: Text(
                          '${preset.output.toInt()}g',
                          style: TextStyle(
                            color:
                                isSelected ? context.colorScheme.inverseSurface : Theme.of(context).primaryColorLight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom temperature selector
          Positioned(
            bottom: Insets.large,
            left: Insets.xxLarge,
            right: Insets.xxLarge,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.temperature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${state.temperatureF.toInt()}°F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(128),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: context.colorScheme.inversePrimary,
                        overlayColor: Colors.transparent,
                        inactiveTrackColor: context.colorScheme.shadow,
                        thumbColor: context.colorScheme.inverseSurface,
                        trackHeight: 20,
                        padding: EdgeInsets.zero,
                      ),
                      child: Slider(
                        value: state.temperatureF,
                        min: 190.0,
                        max: 205.0,
                        onChanged: state.onTemperatureChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-right confirmation button with brew ratio display
          Positioned(
            top: Insets.xSmall,
            right: Insets.xSmall,
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.inversePrimary,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  padding: const EdgeInsets.all(Insets.medium),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: state.onConfirm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 32,
                      color: context.colorScheme.inverseSurface,
                    ),
                    Text(
                      state.brewRatio.formatted,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: context.colorScheme.inverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
